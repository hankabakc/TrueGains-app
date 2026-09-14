package com.gym.v2.auth.service;

import com.gym.v2.auth.dto.AuthResponse;
import com.gym.v2.auth.dto.AuthServiceResult;
import com.gym.v2.auth.dto.LoginRequest;
import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.BlacklistedToken;
import com.gym.v2.auth.entity.RefreshToken;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.exception.PhoneNotVerifiedException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.JwtService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Locale;

import com.gym.v2.core.security.SecurityConstants;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.springframework.security.authentication.BadCredentialsException;

@Service
public class AuthenticationService {

	private static final Logger logger = LoggerFactory.getLogger(AuthenticationService.class);

	/** Hesabın geçici olarak kilitleneceği ardışık başarısız giriş sayısı. */
	private static final int MAX_FAILED_LOGINS = 5;

	/** Eşik aşıldığında hesabın kilitli kalacağı süre (dakika). */
	private static final int LOCKOUT_MINUTES = 15;

	/** Üretilen OTP kodunun geçerlilik süresi (dakika). */
	private static final int OTP_TTL_MINUTES = 5;

	/** Bir OTP kodunun en fazla kaç kez yanlış denenebileceği. */
	private static final int OTP_MAX_ATTEMPTS = 5;

	/** İki OTP gönderimi arasında beklenmesi gereken en kısa süre (saniye). */
	private static final int OTP_RESEND_COOLDOWN_SECONDS = 60;

	private final AppUserRepository userRepository;

	private final RefreshTokenRepository refreshTokenRepository;

	private final BlacklistedTokenRepository blacklistedTokenRepository;

	private final CoachRepository coachRepository;

	private final ClientRepository clientRepository;

	private final PasswordEncoder passwordEncoder;

	private final JwtService jwtService;

	private final AuthenticationManager authenticationManager;

	private final AuthMapper authMapper;

	private final MessageSource messageSource;

	private final Clock clock;

	private final EncryptionConverter encryptionConverter;

	private final OtpService otpService;

	public AuthenticationService(AppUserRepository userRepository, RefreshTokenRepository refreshTokenRepository,
			BlacklistedTokenRepository blacklistedTokenRepository, CoachRepository coachRepository,
			ClientRepository clientRepository, PasswordEncoder passwordEncoder, JwtService jwtService,
			AuthenticationManager authenticationManager, AuthMapper authMapper, MessageSource messageSource,
			Clock clock, EncryptionConverter encryptionConverter, OtpService otpService) {
		this.userRepository = userRepository;
		this.refreshTokenRepository = refreshTokenRepository;
		this.blacklistedTokenRepository = blacklistedTokenRepository;
		this.coachRepository = coachRepository;
		this.clientRepository = clientRepository;
		this.passwordEncoder = passwordEncoder;
		this.jwtService = jwtService;
		this.authenticationManager = authenticationManager;
		this.authMapper = authMapper;
		this.messageSource = messageSource;
		this.clock = clock;
		this.encryptionConverter = encryptionConverter;
		this.otpService = otpService;
	}

	@Transactional
	public void register(RegisterRequest request) {
		if (request.role() == UserRole.ADMIN) {
			if (logger.isWarnEnabled()) {
				logger.warn("[SECURITY] ADMIN rolü ile dışarıdan kayıt denemesi: {}", maskEmail(request.email()));
			}
			throw new BadRequestException(
					messageSource.getMessage("error.auth.invalid-role", null, LocaleContextHolder.getLocale()));
		}
		String normalizedEmail = request.email().toLowerCase(Locale.ROOT).strip();
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Yeni kayıt denemesi: {}", maskEmail(normalizedEmail));
		}
		// Aynı e-postayla DOĞRULANMAMIŞ bir kayıt varsa yenisi onun yerine geçer.
		// Böylece OTP ekranından geri çıkan kullanıcı aynı adresle tekrar kaydolabilir ve
		// "kaydı sunucudan sil" diye kimliksiz bir uç tutmaya gerek kalmaz. O uç,
		// e-postayı
		// bilen herkesin OTP ekranında bekleyen bir kaydı silmesine izin veriyordu.
		// Doğrulanmış hesaplar bu yoldan ASLA etkilenmez.
		userRepository.findByEmail(normalizedEmail).ifPresent(existing -> {
			if (Boolean.TRUE.equals(existing.getIsPhoneVerified())) {
				if (logger.isWarnEnabled()) {
					logger.warn("[AUTH] Kayıt başarısız, e-posta zaten kullanımda: {}", maskEmail(normalizedEmail));
				}
				throw new BadRequestException(
						messageSource.getMessage("error.auth.email-in-use", null, LocaleContextHolder.getLocale()));
			}
			deleteUnverifiedRegistration(existing);
		});

		String otp = otpService.generateOtp();

		AppUser user = AppUser.builder()
			.email(normalizedEmail)
			.password(passwordEncoder.encode(request.password()))
			.role(request.role())
			.registeredAt(clock.instant())
			.phoneNumber(request.phoneNumber())
			.otpCode(otp)
			.otpExpiresAt(clock.instant().plus(OTP_TTL_MINUTES, ChronoUnit.MINUTES))
			.otpLastSentAt(clock.instant())
			.isPhoneVerified(false)
			.build();

		AppUser savedUser = userRepository.saveAndFlush(user);

		// SMS Simülasyonu
		otpService.sendOtpSimulation(request.phoneNumber(), otp);

		String fullName = request.firstName() + " " + request.lastName();

		if (UserRole.COACH == request.role()) {
			coachRepository.save(authMapper.toCoachEntity(savedUser, fullName, request));
		}
		else {
			clientRepository.save(authMapper.toClientEntity(savedUser, fullName, request));
		}

		// Güvenlik: Telefon doğrulanana kadar token verilmez. Oturum, OTP doğrulamasından
		// sonra (verifyOtp) açılır.
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Kayıt başarılı, OTP doğrulaması bekleniyor: {} (Rol: {})",
					maskEmail(savedUser.getEmail()), savedUser.getRole());
		}
	}

	/**
	 * Verilen kodu kullanıcının bekleyen OTP'sine karşı doğrular. Süresi dolmuş kodu
	 * yakar, hatalı denemeleri sayar ve sınır aşıldığında kodu geçersiz kılar.
	 * <p>
	 * Hem telefon doğrulama ({@code verifyOtp}) hem şifre sıfırlama
	 * ({@code resetPassword}) yollarında kullanılır; ikisi de aynı kaba kuvvet korumasına
	 * tabidir.
	 * </p>
	 * @throws BadRequestException kod yok, süresi dolmuş, hatalı veya deneme sınırı
	 * aşılmışsa
	 */
	private void validateOtpOrThrow(AppUser user, String code) {
		if (user.getOtpCode() == null) {
			throw new BadRequestException("Geçersiz doğrulama kodu.");
		}

		// Süresi dolmuş kod yakılır; kullanıcı yeniden gönderim istemek zorundadır.
		if (user.getOtpExpiresAt() == null || !user.getOtpExpiresAt().isAfter(clock.instant())) {
			user.setOtpCode(null);
			userRepository.save(user);
			throw new BadRequestException("Doğrulama kodunun süresi doldu. Lütfen yeni kod isteyin.");
		}

		if (!user.getOtpCode().equals(code)) {
			int attempts = user.getOtpAttemptCount() == null ? 1 : user.getOtpAttemptCount() + 1;
			if (attempts >= OTP_MAX_ATTEMPTS) {
				// Kaba kuvvet koruması: kod yakılır, yeniden gönderim gerekir.
				user.setOtpCode(null);
				user.setOtpAttemptCount(0);
				userRepository.save(user);
				if (logger.isWarnEnabled()) {
					logger.warn("[SECURITY] OTP deneme sınırı aşıldı, kod geçersiz kılındı: {}",
							maskEmail(user.getEmail()));
				}
				throw new BadRequestException("Çok fazla hatalı deneme. Lütfen yeni kod isteyin.");
			}
			user.setOtpAttemptCount(attempts);
			userRepository.save(user);
			throw new BadRequestException("Geçersiz doğrulama kodu.");
		}
	}

	/**
	 * OTP yeniden gönderimi için asgari bekleme süresini uygular (SMS bombardımanı
	 * koruması).
	 * @throws BadRequestException soğuma süresi dolmadan yeni kod istenirse
	 */
	private void assertResendCooldownElapsed(AppUser user) {
		if (isResendCooldownActive(user)) {
			throw new BadRequestException(
					"Yeni kod istemek için " + OTP_RESEND_COOLDOWN_SECONDS + " saniye beklemelisiniz.");
		}
	}

	/**
	 * Soğuma süresinin dolup dolmadığını yalnızca <b>bildirir</b>, hata fırlatmaz.
	 * <p>
	 * Kullanıcının var olduğunun zaten bilindiği akışlarda ({@code resendOtp}) hata
	 * fırlatmak doğrudur; kullanıcının varlığının gizlenmesi gereken akışlarda
	 * ({@code forgotPassword}) fırlatmak bilgi sızdırır. İki davranış bu yüzden ayrıldı.
	 * </p>
	 */
	private boolean isResendCooldownActive(AppUser user) {
		Instant lastSent = user.getOtpLastSentAt();
		return lastSent != null && lastSent.plusSeconds(OTP_RESEND_COOLDOWN_SECONDS).isAfter(clock.instant());
	}

	/**
	 * Yeni bir OTP üretip kullanıcıya işler ve gönderir. Kodun son kullanma anını
	 * tazeler, gönderim anını kaydeder ve önceki koda ait hatalı deneme sayacını
	 * sıfırlar.
	 * @param user OTP gönderilecek kullanıcı
	 */
	private void issueOtp(AppUser user) {
		String otp = otpService.generateOtp();
		user.setOtpCode(otp);
		user.setOtpExpiresAt(clock.instant().plus(OTP_TTL_MINUTES, ChronoUnit.MINUTES));
		user.setOtpLastSentAt(clock.instant());
		user.setOtpAttemptCount(0);
		userRepository.save(user);
		otpService.sendOtpSimulation(user.getPhoneNumber(), otp);
	}

	/**
	 * Başarısız bir giriş denemesini kaydeder ve eşik aşıldığında hesabı geçici olarak
	 * kilitler.
	 * <p>
	 * E-posta bulunamazsa sessizce çıkar: {@code DaoAuthenticationProvider} var olmayan
	 * kullanıcıyı da {@link BadCredentialsException} olarak bildirdiği için burada ayrım
	 * yapmak kullanıcı sıralama (enumeration) sızıntısına yol açardı.
	 * </p>
	 */
	private void registerFailedLogin(String normalizedEmail) {
		AppUser user = userRepository.findByEmail(normalizedEmail).orElse(null);
		if (user == null) {
			return;
		}

		int attempts = user.getFailedLoginAttempts() == null ? 1 : user.getFailedLoginAttempts() + 1;

		if (attempts >= MAX_FAILED_LOGINS) {
			user.setFailedLoginAttempts(0);
			user.setAccountLockedUntil(clock.instant().plus(LOCKOUT_MINUTES, ChronoUnit.MINUTES));
			if (logger.isWarnEnabled()) {
				logger.warn("[SECURITY] Ardışık {} başarısız giriş, hesap {} dk kilitlendi: {}", MAX_FAILED_LOGINS,
						LOCKOUT_MINUTES, maskEmail(normalizedEmail));
			}
		}
		else {
			user.setFailedLoginAttempts(attempts);
		}

		userRepository.save(user);
	}

	/**
	 * Doğrulanmamış (telefonu onaylanmamış) bir kaydı tamamen siler.
	 * <p>
	 * Kullanıcı OTP ekranından geri çıkıp kaydı iptal ettiğinde çağrılır; girilen tüm
	 * profil verileri (app_user + coach/client) kalıcı olarak temizlenir. Böylece aynı
	 * e-posta ile sonradan giriş denendiğinde hesap bulunmaz ve baştan kayıt gerekir.
	 * </p>
	 * Güvenlik: Yalnızca {@code isPhoneVerified == false} olan hesaplar silinir;
	 * doğrulanmış gerçek hesaplar bu uçtan asla silinemez.
	 */
	/**
	 * Doğrulanmamış bir kaydı ve bağlı profil satırlarını siler.
	 * <p>
	 * Eskiden {@code /auth/cancel-registration} ucundan <b>kimliksiz</b>
	 * çağrılabiliyordu: e-postayı bilen biri, OTP ekranında bekleyen bir kaydı silip
	 * kişinin kaydolmasını engelleyebiliyordu. Uç kaldırıldı; artık yalnızca
	 * {@code register} içinden, aynı e-postayla yeni kayıt geldiğinde çağrılır.
	 * </p>
	 */
	private void deleteUnverifiedRegistration(AppUser user) {
		refreshTokenRepository.deleteAllByUser(user);
		if (user.getRole() == UserRole.COACH) {
			coachRepository.findByUserId(user.getId()).ifPresent(coachRepository::delete);
		}
		else {
			clientRepository.findByUserId(user.getId()).ifPresent(clientRepository::delete);
		}
		userRepository.delete(user);
		userRepository.flush();

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Doğrulanmamış kayıt yenisiyle değiştirildi: {}", maskEmail(user.getEmail()));
		}
	}

	@Transactional
	public void forgotPassword(String email) {
		String normalizedEmail = email.toLowerCase(Locale.ROOT).strip();
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Şifre sıfırlama kodu isteği: {}", maskEmail(normalizedEmail));
		}

		java.util.Optional<AppUser> userOpt = userRepository.findByEmail(normalizedEmail);
		if (userOpt.isEmpty()) {
			if (logger.isInfoEnabled()) {
				logger.info("[AUTH] E-posta bulunamadı, enumeration koruması nedeniyle sessizce çıkılıyor: {}",
						maskEmail(normalizedEmail));
			}
			return;
		}

		AppUser user = userOpt.get();

		// Soğuma süresi dolmadıysa SESSİZCE çıkılır, hata fırlatılmaz.
		// Hata fırlatmak enumeration korumasını birkaç satır yukarıda iptal ediyordu:
		// aynı adrese arka arkaya iki istek atan biri, "60 saniye beklemelisiniz"
		// yanıtını
		// alıyorsa adresin kayıtlı olduğunu, başarı yanıtını alıyorsa kayıtlı olmadığını
		// anlıyordu. İki dal artık istemciye aynı yanıtı veriyor.
		if (isResendCooldownActive(user)) {
			if (logger.isInfoEnabled()) {
				logger.info("[AUTH] Soğuma süresi dolmadı, yeni kod üretilmedi: {}", maskEmail(user.getEmail()));
			}
			return;
		}

		issueOtp(user);

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Şifre sıfırlama kodu gönderildi: {}", maskEmail(user.getEmail()));
		}
	}

	/**
	 * {@code noRollbackFor}: hatalı kod durumunda işlem geri alınırsa deneme sayacındaki
	 * artış silinir ve şifre sıfırlama kodu sınırsız denenebilir hâle gelir.
	 */
	@Transactional(noRollbackFor = BadRequestException.class)
	public void resetPassword(String email, String code, String newPassword) {
		String normalizedEmail = email.toLowerCase(Locale.ROOT).strip();
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Şifre sıfırlama denemesi: {}", maskEmail(normalizedEmail));
		}

		AppUser user = userRepository.findByEmail(normalizedEmail)
			.orElseThrow(() -> new BadRequestException(messageSource
				.getMessage("error.auth.forgot-password.user-not-found", null, LocaleContextHolder.getLocale())));

		validateOtpOrThrow(user, code);

		user.setPassword(passwordEncoder.encode(newPassword));
		user.setOtpCode(null);
		user.setOtpExpiresAt(null);
		user.setOtpAttemptCount(0);
		userRepository.save(user);

		revokeAllSessions(user);

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Şifre sıfırlama başarılı: {}", maskEmail(user.getEmail()));
		}
	}

	/**
	 * Kullanıcının açık tüm oturumlarını kapatır.
	 * <p>
	 * Şifre değiştirmenin veya sıfırlamanın sebebi çoğu zaman hesabın ele geçirildiğinden
	 * şüphelenmektir. Yenileme (refresh) token'ları silinmezse saldırganın oturumu şifre
	 * değişikliğinden sonra da yenilenmeye devam eder; yani şifre değiştirmek saldırganı
	 * dışarı atmaz.
	 * </p>
	 * <p>
	 * Erişim (access) token'ları kısa ömürlüdür ve burada tek tek kara listeye alınamaz —
	 * hangi token'ların dağıtıldığı sunucuda tutulmuyor. Yenileme zinciri kesildiği için
	 * saldırganın erişimi en fazla access token ömrü kadar (bkz. {@code jwt.expiration})
	 * sürer.
	 * </p>
	 */
	private void revokeAllSessions(AppUser user) {
		refreshTokenRepository.deleteAllByUser(user);
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Şifre değişikliği sonrası tüm oturumlar sonlandırıldı: {}", maskEmail(user.getEmail()));
		}
	}

	/**
	 * {@code noRollbackFor}: hatalı/süresi dolmuş kod durumunda işlem geri alınırsa
	 * deneme sayacındaki artış ve kodun yakılması da silinir; kaba kuvvet koruması hiç
	 * işlemez.
	 */
	@Transactional(noRollbackFor = BadRequestException.class)
	public AuthServiceResult verifyOtp(String email, String code) {
		AppUser user = userRepository.findByEmail(email.toLowerCase(Locale.ROOT).strip())
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		if (Boolean.TRUE.equals(user.getIsPhoneVerified())) {
			throw new BadRequestException("Telefon numarası zaten doğrulanmış.");
		}

		validateOtpOrThrow(user, code);

		user.setIsPhoneVerified(true);
		user.setOtpCode(null);
		user.setOtpExpiresAt(null);
		user.setOtpAttemptCount(0);
		userRepository.save(user);

		// Telefon doğrulandı: oturum token'ları artık üretilebilir.
		String accessToken = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
		String refreshToken = createRefreshToken(user, SecurityConstants.DEFAULT_DEVICE_ID);

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Telefon doğrulandı, oturum açıldı: {}", maskEmail(user.getEmail()));
		}
		AuthResponse response = authMapper.toAuthResponse(user, accessToken, jwtService.getJwtExpirationSeconds());
		return new AuthServiceResult(response, refreshToken);
	}

	@Transactional
	public void resendOtp(String email) {
		AppUser user = userRepository.findByEmail(email.toLowerCase(Locale.ROOT).strip())
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		if (Boolean.TRUE.equals(user.getIsPhoneVerified())) {
			throw new BadRequestException("Telefon numarası zaten doğrulanmış.");
		}

		assertResendCooldownElapsed(user);
		issueOtp(user);

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Yeni OTP gönderildi: {}", maskEmail(user.getEmail()));
		}
	}

	/**
	 * {@code noRollbackFor}: hatalı şifre durumunda işlem geri alınırsa başarısız giriş
	 * sayacındaki artış da silinir ve hesap hiçbir zaman kilitlenmez. Bu nedenle
	 * {@link BadCredentialsException} için geri alma devre dışı bırakılmıştır.
	 * {@link PhoneNotVerifiedException} için de: geri alınırsa az önce gönderilen OTP
	 * kodu veritabanından silinir ve kullanıcı gelen kodu giremez.
	 */
	@Transactional(noRollbackFor = { BadCredentialsException.class, PhoneNotVerifiedException.class })
	public AuthServiceResult login(LoginRequest request) {
		String normalizedEmail = request.email().toLowerCase(Locale.ROOT).strip();
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Giriş denemesi: {}", maskEmail(normalizedEmail));
		}
		try {
			authenticationManager
				.authenticate(new UsernamePasswordAuthenticationToken(normalizedEmail, request.password()));
		}
		catch (BadCredentialsException ex) {
			registerFailedLogin(normalizedEmail);
			throw ex;
		}

		AppUser user = userRepository.findByEmail(normalizedEmail)
			.orElseThrow(() -> new NotFoundException(
					messageSource.getMessage("error.auth.user-not-found", null, LocaleContextHolder.getLocale())));

		// Başarılı giriş: kilitleme sayacı sıfırlanır.
		user.setFailedLoginAttempts(0);
		user.setAccountLockedUntil(null);

		// Güvenlik: Telefonu doğrulanmamış hesaba oturum token'ı verilmez. Yeni OTP
		// gönderip
		// istemciyi doğrulama ekranına yönlendirmek üzere 403 fırlatılır.
		//
		// ADMIN bu kapının DIŞINDA. Telefon doğrulaması tüketici KAYIT akışının
		// kapısıdır: kullanıcı kendi numarasını girer, sahipliğini kanıtlar. Yönetici
		// hesapları o akıştan geçmez — `register` ADMIN rolünü zaten reddediyor
		// (bkz. bu sınıfın başı), hesap migrasyonla sağlanıyor ve numarası yok.
		// Kapıyı onlara uygulamak "doğrulanacak bir şey olmadığı için asla
		// doğrulanamaz" demek, yani kalıcı kilit. CLIENT/COACH için kapı aynen
		// yerinde; AuthPhoneGateIT bunu kilitliyor.
		if (user.getRole() != UserRole.ADMIN && !Boolean.TRUE.equals(user.getIsPhoneVerified())) {
			issueOtp(user);
			if (logger.isWarnEnabled()) {
				logger.warn("[AUTH] Doğrulanmamış telefon ile giriş denemesi, OTP tekrar gönderildi: {}",
						maskEmail(user.getEmail()));
			}
			throw new PhoneNotVerifiedException("Telefon numaranız doğrulanmadı. Yeni bir doğrulama kodu gönderildi.");
		}

		// Son giriş yalnızca oturum gerçekten açılınca yazılır; telefon kapısında
		// reddedilen deneme giriş değildir.
		user.setLastLoginAt(clock.instant());

		String accessToken = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
		String refreshToken = createRefreshToken(user, request.deviceId());

		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Giriş başarılı: {} (Rol: {})", maskEmail(user.getEmail()), user.getRole());
		}
		AuthResponse response = authMapper.toAuthResponse(user, accessToken, jwtService.getJwtExpirationSeconds());
		return new AuthServiceResult(response, refreshToken);
	}

	@Transactional
	public AuthServiceResult refreshToken(String refreshTokenStr, String deviceId) {
		RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenStr)
			.orElseThrow(() -> new BadRequestException(messageSource.getMessage("error.auth.invalid-refresh-token",
					null, LocaleContextHolder.getLocale())));

		if (refreshToken.getDeviceId() != null && !refreshToken.getDeviceId().equals(deviceId)) {
			throw new SecurityException("Cihaz kimliği eşleşmiyor. Güvenlik ihlali!");
		}

		if (refreshToken.getExpiryDate().isBefore(clock.instant())) {
			refreshTokenRepository.delete(refreshToken);
			throw new BadRequestException(messageSource.getMessage("error.auth.refresh-token-expired", null,
					LocaleContextHolder.getLocale()));
		}

		AppUser user = refreshToken.getUser();
		String newAccessToken = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
		String newRefreshToken = createRefreshToken(user, deviceId);

		refreshTokenRepository.delete(refreshToken);

		AuthResponse response = authMapper.toAuthResponse(user, newAccessToken, jwtService.getJwtExpirationSeconds());
		return new AuthServiceResult(response, newRefreshToken);
	}

	@Transactional
	public void logout(String token, String email) {
		String jti = jwtService.extractJti(token);
		BlacklistedToken blacklisted = new BlacklistedToken(jti,
				clock.instant().plus(SecurityConstants.BLACKLIST_TOKEN_EXPIRY_HOURS, ChronoUnit.HOURS));
		blacklistedTokenRepository.save(blacklisted);

		AppUser user = userRepository.findByEmail(email).orElse(null);
		if (user != null) {
			refreshTokenRepository.deleteAllByUser(user);
		}
		else {
			if (logger.isWarnEnabled()) {
				logger.warn("[SECURITY] Logout sırasında kullanıcı bulunamadı! E-posta: {}", maskEmail(email));
			}
		}
		if (logger.isInfoEnabled()) {
			logger.info("[AUTH] Çıkış yapıldı: {}", maskEmail(email));
		}
	}

	private String createRefreshToken(AppUser user, String deviceId) {
		RefreshToken refreshToken = new RefreshToken();
		refreshToken.setUser(user);
		refreshToken.setToken(UUID.randomUUID().toString());
		refreshToken.setExpiryDate(clock.instant().plus(SecurityConstants.REFRESH_TOKEN_EXPIRY_DAYS, ChronoUnit.DAYS));
		refreshToken.setDeviceId(deviceId);

		return refreshTokenRepository.save(refreshToken).getToken();
	}

	/**
	 * PII (Kişisel Veri) güvenliği için e-postayı maskeler.
	 */
	private String maskEmail(String email) {
		if (email == null || !email.contains("@")) {
			return "****";
		}
		int atIndex = email.indexOf("@");
		String name = email.substring(0, atIndex);
		String domain = email.substring(atIndex);
		if (name.length() <= 1) {
			return name + "***" + domain;
		}
		return name.charAt(0) + "***" + domain;
	}

}
