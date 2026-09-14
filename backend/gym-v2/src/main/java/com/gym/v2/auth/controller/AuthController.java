package com.gym.v2.auth.controller;

import com.gym.v2.auth.dto.EmailRequest;
import com.gym.v2.auth.dto.VerifyOtpRequest;
import com.gym.v2.auth.dto.AuthResponse;
import com.gym.v2.auth.dto.AuthServiceResult;
import com.gym.v2.auth.dto.LoginRequest;
import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.dto.TokenRefreshRequest;
import com.gym.v2.auth.dto.ResetPasswordRequest;
import com.gym.v2.auth.service.AuthenticationService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.core.exception.BadRequestException;
import jakarta.validation.Valid;
import java.time.Clock;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CookieValue;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Kimlik doğrulama işlemlerini yöneten REST denetleyicisi.
 * <p>
 * Bu sınıf; kullanıcı kaydı, girişi, token yenileme ve çıkış işlemlerini gerçekleştirmek
 * için {@link AuthenticationService} sınıfını kullanır.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> İstemciden gelen HTTP POST isteklerini karşılar ve ilgili
 * servis metotlarına yönlendirir. Gelen istek gövdeleri (request bodies) validasyon
 * sürecinden geçer.
 *
 * <h2>Neden Bu Sınıf Var?</h2> Uygulamanın güvenliğini sağlamak ve kullanıcıların sisteme
 * erişimini yönetmek için merkezi bir API giriş noktası sağlar.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

	private final AuthenticationService authenticationService;

	private final MessageSource messageSource;

	private final Clock clock;

	/**
	 * AuthController yapılandırıcısı.
	 * @param authenticationService Kimlik doğrulama işlemlerini gerçekleştiren servis.
	 * @param messageSource i18n dil desteği için Spring MessageSource.
	 * @param clock Zaman damgaları için merkezi saat bean'i.
	 */
	public AuthController(AuthenticationService authenticationService, MessageSource messageSource, Clock clock) {
		this.authenticationService = authenticationService;
		this.messageSource = messageSource;
		this.clock = clock;
	}

	/**
	 * Yeni bir kullanıcı kaydı oluşturur.
	 * <p>
	 * Gelen {@link RegisterRequest} verilerini {@link AuthenticationService#register}
	 * metoduna ileterek yeni bir hesap oluşturulmasını sağlar. İşlem sonucunda bir kimlik
	 * doğrulama yanıtı döner.
	 * </p>
	 * @param request Kayıt için gerekli kullanıcı bilgilerini içeren nesne.
	 * @return Kayıt sonucunu ve kimlik doğrulama verilerini içeren {@link ApiResponse}.
	 */
	@PostMapping("/register")
	public ResponseEntity<ApiResponse<Void>> register(@RequestBody @Valid RegisterRequest request) {
		// Güvenlik: Kayıt token vermez. Oturum, OTP doğrulamasından sonra açılır.
		authenticationService.register(request);

		String message = messageSource.getMessage("messages.auth.register.success", null,
				LocaleContextHolder.getLocale());
		return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(null, message, clock.instant()));
	}

	/**
	 * Mevcut bir kullanıcıyı sisteme dahil eder.
	 * <p>
	 * E-posta ve şifre bilgilerini kontrol ederek başarılı bir giriş durumunda JWT
	 * token'ları üretir.
	 * </p>
	 * @param request Giriş bilgilerini içeren nesne.
	 * @return Giriş başarısını ve üretilen token'ları içeren {@link ApiResponse}.
	 */
	@PostMapping("/login")
	public ResponseEntity<ApiResponse<AuthResponse>> login(@RequestBody @Valid LoginRequest request) {
		AuthServiceResult result = authenticationService.login(request);

		ResponseCookie cookie = createRefreshTokenCookie(result.refreshToken(),
				SecurityConstants.REFRESH_TOKEN_COOKIE_MAX_AGE);

		String message = messageSource.getMessage("messages.auth.login.success", null, LocaleContextHolder.getLocale());
		return ResponseEntity.ok()
			.header(HttpHeaders.SET_COOKIE, cookie.toString())
			.body(ApiResponse.success(result.response(), message, clock.instant()));
	}

	/**
	 * Geçerli bir yenileme token'ı (Refresh Token) kullanarak yeni bir erişim token'ı
	 * üretir.
	 * <p>
	 * Bu işlem, kullanıcının oturum süresini şifresini tekrar sormadan uzatmak için
	 * yapılır.
	 * </p>
	 * @param request Yenileme token'ı ve cihaz kimliğini içeren nesne.
	 * @return Yeni üretilen token'ları içeren {@link ApiResponse}.
	 */
	@PostMapping("/refresh")
	public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(
			@CookieValue(name = SecurityConstants.REFRESH_TOKEN_COOKIE_NAME, required = false) String refreshToken,
			@RequestBody @Valid TokenRefreshRequest request) {

		if (refreshToken == null || refreshToken.isBlank()) {
			throw new BadRequestException(messageSource.getMessage("error.auth.refresh-token-missing", null,
					LocaleContextHolder.getLocale()));
		}
		AuthServiceResult result = authenticationService.refreshToken(refreshToken, request.deviceId());

		ResponseCookie cookie = createRefreshTokenCookie(result.refreshToken(),
				SecurityConstants.REFRESH_TOKEN_COOKIE_MAX_AGE);

		String message = messageSource.getMessage("messages.auth.refresh.success", null,
				LocaleContextHolder.getLocale());
		return ResponseEntity.ok()
			.header(HttpHeaders.SET_COOKIE, cookie.toString())
			.body(ApiResponse.success(result.response(), message, clock.instant()));
	}

	/**
	 * Kullanıcının mevcut oturumunu sonlandırır.
	 * <p>
	 * Authorization başlığından alınan JWT token'ını geçersiz kılar ve oturum verilerini
	 * temizler.
	 * </p>
	 * @param authHeader "Bearer {token}" formatındaki yetkilendirme başlığı.
	 * @return Çıkış işleminin sonucunu belirten {@link ApiResponse}.
	 */
	@PostMapping("/logout")
	public ResponseEntity<ApiResponse<Void>> logout(
			@RequestHeader(value = HttpHeaders.AUTHORIZATION, required = false) String authHeader) {
		String token = SecurityUtils.extractToken(authHeader);
		if (token != null) {
			String email = SecurityUtils.getCurrentUserEmail();
			authenticationService.logout(token, email);
		}

		ResponseCookie cookie = createRefreshTokenCookie("", 0);

		String message = messageSource.getMessage("messages.auth.logout.success", null,
				LocaleContextHolder.getLocale());
		return ResponseEntity.ok()
			.header(HttpHeaders.SET_COOKIE, cookie.toString())
			.body(ApiResponse.success(null, message, clock.instant()));
	}

	@PostMapping("/forgot-password")
	public ResponseEntity<ApiResponse<Void>> forgotPassword(@RequestBody @Valid EmailRequest request) {
		authenticationService.forgotPassword(request.email());
		String message = messageSource.getMessage("messages.auth.forgot-password.success", null,
				LocaleContextHolder.getLocale());
		return ResponseEntity.ok(ApiResponse.success(null, message, clock.instant()));
	}

	@PostMapping("/reset-password")
	public ResponseEntity<ApiResponse<Void>> resetPassword(@RequestBody @Valid ResetPasswordRequest request) {
		authenticationService.resetPassword(request.email(), request.code(), request.newPassword());
		String message = messageSource.getMessage("messages.auth.reset-password.success", null,
				LocaleContextHolder.getLocale());
		return ResponseEntity.ok(ApiResponse.success(null, message, clock.instant()));
	}

	@PostMapping("/verify-otp")
	public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(@RequestBody @Valid VerifyOtpRequest request) {
		// Doğrulama başarılıysa oturum token'ları burada üretilir.
		AuthServiceResult result = authenticationService.verifyOtp(request.email(), request.code());

		ResponseCookie cookie = createRefreshTokenCookie(result.refreshToken(),
				SecurityConstants.REFRESH_TOKEN_COOKIE_MAX_AGE);

		return ResponseEntity.ok()
			.header(HttpHeaders.SET_COOKIE, cookie.toString())
			.body(ApiResponse.success(result.response(), "Telefon numaranız başarıyla doğrulandı.", clock.instant()));
	}

	@PostMapping("/resend-otp")
	public ResponseEntity<ApiResponse<Void>> resendOtp(@RequestBody @Valid EmailRequest request) {
		authenticationService.resendOtp(request.email());
		return ResponseEntity.ok(ApiResponse.success(null, "Yeni doğrulama kodu gönderildi.", clock.instant()));
	}

	private ResponseCookie createRefreshTokenCookie(String token, long maxAge) {
		return ResponseCookie.from(SecurityConstants.REFRESH_TOKEN_COOKIE_NAME, token)
			.httpOnly(true)
			.secure(true) // Production için true olmalı
			.path("/api/v1/auth/refresh")
			.maxAge(maxAge)
			.sameSite("Strict")
			.build();
	}

}
