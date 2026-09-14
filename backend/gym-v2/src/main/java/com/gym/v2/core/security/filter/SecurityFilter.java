package com.gym.v2.core.security.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.security.service.RateLimitingService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import org.jsoup.Jsoup;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.beans.factory.annotation.Value;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.time.Clock;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

/**
 * Global WAF (Web Application Firewall) ve Rate Limiting Filtresi. SQL Injection, XSS ve
 * DoS saldırılarını kapıda durdurur. Jsoup tabanlı içerik taraması ve X-Forwarded-For
 * desteği içerir.
 */
@Component
public class SecurityFilter extends OncePerRequestFilter {

	private static final Logger log = LoggerFactory.getLogger(SecurityFilter.class);

	private final RateLimitingService rateLimitingService;

	@Value("${app.security.waf.enabled:true}")
	private boolean wafEnabled;

	/**
	 * {@code X-Forwarded-For} başlığına yalnızca, bu başlığı ezen güvenilir bir ters
	 * vekil (reverse proxy) uygulamanın önünde konumlandığında güvenilmelidir. Aksi hâlde
	 * istemci başlığı kendisi uydurup her istekte farklı bir IP bildirerek hız
	 * sınırlamasını tamamen atlatabilir. Bu nedenle varsayılan {@code false}'tur.
	 */
	@Value("${app.security.rate-limit.trust-forwarded-header:false}")
	private boolean trustForwardedHeader;

	private final ObjectMapper objectMapper;

	private final Clock clock;

	public SecurityFilter(RateLimitingService rateLimitingService, ObjectMapper objectMapper, Clock clock) {
		this.rateLimitingService = rateLimitingService;
		this.objectMapper = objectMapper;
		this.clock = clock;
	}

	/** Kaba kuvvet hedefi olan kimlik doğrulama uçlarının ortak ön eki. */
	private static final String AUTH_PATH_PREFIX = "/api/v1/auth/";

	/** Kimliksiz çağrılabilen tek yazma ucu; kendi dar kovasını kullanır. */
	private static final String UPLOAD_PATH = "/api/v1/files/upload";

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {

		String ipAddress = extractClientIp(request);
		String path = request.getRequestURI();

		// 1. Rate Limiting Kontrolü. Kimlik doğrulama uçları kendi dar kovasını kullanır;
		// böylece brute-force denemeleri normal gezinme bütçesinden bağımsız sınırlanır.
		// WebSocket EL SIKIŞMASI da sınırlanır: daha önce /ws tamamen muaftı ve tek
		// istemci
		// sınırsız handshake açarak sunucu iş parçacıklarını tüketebiliyordu. Bağlantı
		// kurulduktan sonraki STOMP kareleri bu filtreden geçmez, yalnızca handshake
		// sayılır.
		String bucketName;
		io.github.bucket4j.Bucket bucket;
		if (path.startsWith(AUTH_PATH_PREFIX)) {
			bucketName = "auth";
			bucket = rateLimitingService.resolveAuthBucket(ipAddress);
		}
		else if (UPLOAD_PATH.equals(path)) {
			bucketName = "yukleme";
			bucket = rateLimitingService.resolveUploadBucket(ipAddress);
		}
		else {
			bucketName = "genel";
			bucket = rateLimitingService.resolveBucket(ipAddress);
		}

		if (!bucket.tryConsume(1)) {
			log.warn("[SECURITY] Rate limit aşıldı! IP: {}, Path: {}, Kova: {}", ipAddress, path, bucketName);
			writeError(response, 429, "Çok fazla istek attınız. Lütfen bekleyin.");
			return;
		}

		// Eğer WAF kapalıysa direkt devam et
		if (!wafEnabled) {
			filterChain.doFilter(request, response);
			return;
		}

		// 2. WAF Kontrolü (URL ve Query String Taraması)
		StringBuilder inputToScan = new StringBuilder(path);
		if (request.getQueryString() != null) {
			inputToScan.append("?").append(request.getQueryString());
		}

		String decodedInput;
		try {
			decodedInput = URLDecoder.decode(inputToScan.toString(), StandardCharsets.UTF_8);
		}
		catch (IllegalArgumentException e) {
			response.setStatus(400);
			return;
		}

		if (isMalicious(decodedInput)) {
			log.error("[SECURITY] Zararlı içerik (URL/Query) tespit edildi! IP: {}, Input: {}", ipAddress,
					decodedInput);
			blockRequest(response);
			return;
		}

		// 3. Gövde Taraması. Gövde yalnızca bir kez okunabildiği için istek sarmalanır ve
		// zincire sarmalanmış hâli devredilir; aksi hâlde controller boş gövde görür.
		HttpServletRequest downstreamRequest = request;
		if (shouldScanBody(request)) {
			CachedBodyHttpServletRequest cachedRequest = new CachedBodyHttpServletRequest(request);
			downstreamRequest = cachedRequest;

			byte[] bodyBytes = cachedRequest.getCachedBody();
			if (bodyBytes != null && bodyBytes.length > 0) {
				String body = new String(bodyBytes, StandardCharsets.UTF_8);
				if (isMalicious(body)) {
					log.error("[SECURITY] Zararlı içerik (Body) tespit edildi! IP: {}", ipAddress);
					blockRequest(response);
					return;
				}
			}
		}

		filterChain.doFilter(downstreamRequest, response);
	}

	/**
	 * Gövdesi olan isteklerde tarama yapılır. Dosya yüklemeleri (multipart) kapsam
	 * dışıdır: ikili içerik bellekte tutulmamalı ve HTML taramasından geçirilmemelidir.
	 */
	private boolean shouldScanBody(HttpServletRequest request) {
		String method = request.getMethod();
		if (!"POST".equalsIgnoreCase(method) && !"PUT".equalsIgnoreCase(method) && !"PATCH".equalsIgnoreCase(method)) {
			return false;
		}
		String contentType = request.getContentType();
		return contentType == null || !contentType.toLowerCase().startsWith("multipart/");
	}

	/**
	 * Jsoup kullanarak içeriğin zararlı olup olmadığını kontrol eder (Bulgu #6).
	 */
	private boolean isMalicious(String input) {
		if (input == null || input.isBlank()) {
			return false;
		}

		// Aranan şey, metnin gerçekten bir HTML/script ETİKETİ üretip üretmediğidir.
		//
		// Önceki sürüm Jsoup.isValid(input, Safelist.none()) kullanıyordu ve bu, düz
		// metni de reddediyordu: "Hedefim < 80 kg" gibi sıradan bir cümle HTML olarak
		// normalize edilince değiştiği için "zararlı" sayılıp 403 alıyordu. Serbest metin
		// taşıyan her uç (sohbet, biyografi, besin adı, not) bundan etkileniyordu.
		//
		// Tespit gücü kaybedilmedi: etiket üretmeyen girdiler (SQL denemeleri,
		// "javascript:..." gibi düz metinler) eski sürümde de zaten engellenmiyordu.
		return !Jsoup.parseBodyFragment(input).body().children().isEmpty();
	}

	/**
	 * İstemci IP'sini çözer. {@code X-Forwarded-For} yalnızca yapılandırma ile açıkça
	 * güvenilir ilan edildiğinde dikkate alınır; aksi hâlde TCP bağlantısının gerçek
	 * kaynak adresi kullanılır.
	 */
	private String extractClientIp(HttpServletRequest request) {
		if (trustForwardedHeader) {
			String xff = request.getHeader("X-Forwarded-For");
			if (xff != null && !xff.isBlank()) {
				return xff.split(",")[0].strip();
			}
		}
		return request.getRemoteAddr();
	}

	private void blockRequest(HttpServletResponse response) throws IOException {
		writeError(response, 403, "Güvenlik ihlali tespit edildi.");
	}

	/**
	 * Hata yanıtlarını uygulamanın standart {@code ApiResponse} zarfıyla yazar.
	 * <p>
	 * Daha önce düz metin dönülüyordu; istemci her yanıtı {@code ApiResponse} olarak
	 * ayrıştırdığı için 429/403 durumlarında mesaj gösterilemiyordu.
	 * </p>
	 */
	private void writeError(HttpServletResponse response, int status, String message) throws IOException {
		response.setStatus(status);
		response.setContentType(MediaType.APPLICATION_JSON_VALUE);
		response.setCharacterEncoding("UTF-8");
		response.getWriter().write(objectMapper.writeValueAsString(ApiResponse.error(message, clock.instant())));
	}

	/**
	 * HTTP gövdesini bellekte tutan sarmalayıcı. Gövde hem burada taranır hem de
	 * controller tarafından okunabilir kalır.
	 */
	private static final class CachedBodyHttpServletRequest extends HttpServletRequestWrapper {

		private final byte[] cachedBody;

		private CachedBodyHttpServletRequest(HttpServletRequest request) throws IOException {
			super(request);
			try (InputStream requestInputStream = request.getInputStream()) {
				this.cachedBody = requestInputStream.readAllBytes();
			}
		}

		@Override
		public ServletInputStream getInputStream() {
			return new CachedBodyServletInputStream(this.cachedBody);
		}

		@Override
		public BufferedReader getReader() {
			return new BufferedReader(
					new InputStreamReader(new ByteArrayInputStream(this.cachedBody), StandardCharsets.UTF_8));
		}

		private byte[] getCachedBody() {
			return this.cachedBody;
		}

	}

	/**
	 * Bellekteki veriden okuma yapan ServletInputStream.
	 */
	private static final class CachedBodyServletInputStream extends ServletInputStream {

		private final ByteArrayInputStream cachedBodyInputStream;

		CachedBodyServletInputStream(byte[] cachedBody) {
			this.cachedBodyInputStream = new ByteArrayInputStream(cachedBody);
		}

		@Override
		public boolean isFinished() {
			return cachedBodyInputStream.available() == 0;
		}

		@Override
		public boolean isReady() {
			return true;
		}

		@Override
		public void setReadListener(ReadListener readListener) {
			throw new UnsupportedOperationException();
		}

		@Override
		public int read() {
			return cachedBodyInputStream.read();
		}

	}

}
