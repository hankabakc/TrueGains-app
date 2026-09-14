package com.gym.v2.core.security.config;

import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.core.security.filter.JwtAuthenticationFilter;
import com.gym.v2.core.security.filter.SecurityFilter;
import org.springframework.beans.factory.annotation.Value;
import org.slf4j.LoggerFactory;
import org.springframework.boot.security.autoconfigure.actuate.web.servlet.EndpointRequest;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.core.annotation.Order;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AccountStatusUserDetailsChecker;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.http.HttpMethod;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

	@Value("${app.security.cors.allowed-origins:http://localhost:3000,http://localhost:8080,capacitor://localhost}")
	private List<String> allowedOrigins;

	@Value("${app.swagger.enabled:false}")
	private boolean swaggerEnabled;

	private final JwtAuthenticationFilter jwtAuthFilter;

	private final SecurityFilter securityFilter;

	public SecurityConfig(JwtAuthenticationFilter jwtAuthFilter, SecurityFilter securityFilter) {
		this.jwtAuthFilter = jwtAuthFilter;
		this.securityFilter = securityFilter;
	}

	/**
	 * İşletim uçları için ayrı filtre zinciri.
	 * <p>
	 * Actuator uçları ayrı bir yönetim portunda yayınlanıyor ve o port dışarı açılmıyor
	 * (bkz. {@code application.properties} ve {@code docker-compose.yml}). Güvenlik
	 * sınırı burada <b>ağ</b>: uca yalnızca aynı compose ağındaki Prometheus
	 * ulaşabiliyor.
	 * </p>
	 * <p>
	 * Bu zincir olmadan ana zincirin {@code anyRequest().authenticated()} kuralı yönetim
	 * portunda da geçerli oluyor ve Prometheus kazıması <b>403</b> alıyordu. Alternatif —
	 * Prometheus'a uygulama kimliği vermek — hem gereksiz hem de metrik toplayıcıya
	 * kullanıcı hesabı açmak demekti.
	 * </p>
	 * <p>
	 * API portunda bu yollar zaten eşleşmiyor (uçlar orada mapping'e sahip değil), bu
	 * yüzden izin vermek oradan bilgi sızdırmıyor; {@code OperationsEndpointsIT} API
	 * portundan hiçbir actuator ucunun içerik döndürmediğini doğruluyor.
	 * </p>
	 */
	@Bean
	@Order(0)
	public SecurityFilterChain actuatorSecurityFilterChain(HttpSecurity http) throws Exception {
		http.securityMatcher(EndpointRequest.toAnyEndpoint())
			.csrf(AbstractHttpConfigurer::disable)
			.authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
		return http.build();
	}

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		http.csrf(AbstractHttpConfigurer::disable)
			.cors(cors -> cors.configurationSource(corsConfigurationSource()))
			.authorizeHttpRequests(auth -> {
				// Not: /api/v1/webhooks/** bilerek permitAll DEĞİL. Bugün bu ucu gerçek
				// bir
				// ödeme sağlayıcısı değil, uygulamanın kendi mock akışı çağırıyor
				// (finance_api_service.triggerPaymentWebhook). Gerçek sağlayıcı
				// bağlandığında
				// buranın sağlayıcının imzasını doğrulaması gerekir.
				auth.requestMatchers("/api/v1/auth/**")
					.permitAll()
					.requestMatchers(HttpMethod.POST, "/api/v1/files/upload")
					.permitAll()
					.requestMatchers(HttpMethod.GET, "/api/v1/files/**")
					.permitAll()
					.requestMatchers("/ws/**")
					.permitAll()
					// NOT: actuator uçları artık bu portta değil, ayrı yönetim
					// portunda yayınlanıyor (application.properties:
					// management.server.port). Buradaki eski `permitAll` kuralı
					// kaldırıldı — kalsaydı okuyan "sağlık ucu 8082'de açık" sanırdı.
					// Yönetim portu compose ağında kalıyor, dışarı açılmıyor.
					// Sürüm kontrolü açılışta, giriş yapılmadan sorulur.
					.requestMatchers(HttpMethod.GET, "/api/v1/app/version")
					.permitAll();

				// Swagger Security (Bulgu #2)
				if (swaggerEnabled) {
					auth.requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html", "/swagger",
							"/swagger-resources/**", "/webjars/**")
						.permitAll();
				}

				// Yonetim paneli. ADMIN rolu enum'da vardi ama HICBIR uc onu kontrol
				// etmiyordu; admin hesabinin fiilen ayricaligi yoktu. Bu kural o bosluğu
				// kapatiyor. Disaridan ADMIN olarak kayit zaten engelli
				// (AuthenticationService.register).
				auth.requestMatchers("/api/v1/admin/**").hasRole("ADMIN");

				auth.anyRequest().authenticated();
			})
			.headers(headers -> headers.xssProtection(xss -> xss.disable())
				.frameOptions(frame -> frame.deny())
				.contentSecurityPolicy(
						csp -> csp.policyDirectives("default-src 'self'; script-src 'self'; object-src 'none';"))
				.httpStrictTransportSecurity(hsts -> hsts.includeSubDomains(true).maxAgeInSeconds(31536000)))
			.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
			.addFilterBefore(securityFilter, UsernamePasswordAuthenticationFilter.class)
			.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

		return http.build();
	}

	// Filtreler @Component olduğu için Boot bunları ayrıca servlet konteynerine de
	// kaydeder; zincirdeki kayıtla birlikte her istekte iki kez çalışırlardı.
	// OncePerRequestFilter şu an bunu perdeliyor, ancak niyeti açık tutmak için
	// otomatik kayıt kapatılır: filtreler yalnızca SecurityFilterChain üzerinden koşar.
	@Bean
	public FilterRegistrationBean<SecurityFilter> securityFilterRegistration() {
		return disableAutoRegistration(securityFilter);
	}

	@Bean
	public FilterRegistrationBean<JwtAuthenticationFilter> jwtAuthenticationFilterRegistration() {
		return disableAutoRegistration(jwtAuthFilter);
	}

	private <T extends jakarta.servlet.Filter> FilterRegistrationBean<T> disableAutoRegistration(T filter) {
		FilterRegistrationBean<T> registration = new FilterRegistrationBean<>(filter);
		registration.setEnabled(false);
		return registration;
	}

	/**
	 * CORS izinli adresleri.
	 * <p>
	 * Varsayılan yalnızca yerel geliştirme adresleridir. Üretimde
	 * {@code APP_SECURITY_CORS_ALLOWED_ORIGINS} ortam değişkeniyle gerçek alan adı
	 * verilmelidir; verilmezse web sürümünde tarayıcı tüm istekleri bloklar. Mobil
	 * uygulama CORS kullanmadığı için bu eksik bugün fark edilmiyor — sessizce yanlış
	 * kalan bir yapılandırma olduğu için açılışta hangi adreslerin etkin olduğu
	 * loglanıyor.
	 * </p>
	 */
	@Bean
	public CorsConfigurationSource corsConfigurationSource() {
		// `*` ile allowCredentials=true birlikte kullanılamaz. Spring bunu istek anında
		// fark edip anlaşılmaz bir hata veriyor; açılışta ve açık mesajla durmak, hatayı
		// üretimde ilk isteği atan kullanıcının bulmasından iyidir.
		if (allowedOrigins.contains("*")) {
			throw new IllegalStateException("app.security.cors.allowed-origins '*' olamaz: kimlik bilgisi taşıyan "
					+ "isteklerde joker origin tarayıcı tarafından reddedilir. Ortam başına gerçek alan adı verin.");
		}

		LoggerFactory.getLogger(SecurityConfig.class).info("[CORS] İzinli adresler: {}", allowedOrigins);

		CorsConfiguration configuration = new CorsConfiguration();
		// Açık origin tanımı (Bulgu #1)
		configuration.setAllowedOrigins(allowedOrigins);
		configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
		configuration.setAllowedHeaders(Arrays.asList(SecurityConstants.AUTH_HEADER, "Content-Type", "X-Requested-With",
				"Accept", "Origin", "X-Device-ID"));
		configuration.setExposedHeaders(List.of(SecurityConstants.AUTH_HEADER));
		configuration.setAllowCredentials(true);
		configuration.setMaxAge(3600L);
		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", configuration);
		return source;
	}

	@Bean
	public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
		return config.getAuthenticationManager();
	}

	/**
	 * Kilit ve pasif hesap kontrolü şifre doğrulamasının ARKASINDA yapılır.
	 * <p>
	 * Spring varsayılanı bu kontrolü şifreden önce yapıyor: yanlış şifreyle bile "hesap
	 * kilitli / kapatıldı" cevabı dönüyor ve e-postanın kayıtlı olduğu şifresiz
	 * öğreniliyor. Şifre yanlışsa önce BadCredentialsException gelir; hesap durumu
	 * yalnızca şifreyi bilen kişiye söylenir (kullanıcı kararı, 13.09.2026).
	 * </p>
	 */
	@Bean
	public DaoAuthenticationProvider authenticationProvider(UserDetailsService userDetailsService,
			PasswordEncoder passwordEncoder) {
		DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
		provider.setPasswordEncoder(passwordEncoder);
		provider.setPreAuthenticationChecks((user) -> {
			// Bilerek boş: hesap durumu şifreden sonra kontrol ediliyor.
		});
		provider.setPostAuthenticationChecks(new AccountStatusUserDetailsChecker());
		return provider;
	}

	@Bean
	public PasswordEncoder passwordEncoder() {
		return new BCryptPasswordEncoder();
	}

}
