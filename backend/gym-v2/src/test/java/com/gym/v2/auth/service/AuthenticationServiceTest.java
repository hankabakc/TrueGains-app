package com.gym.v2.auth.service;

import com.gym.v2.auth.RegisterRequestFixture;
import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.RefreshToken;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.JwtService;
import com.gym.v2.auth.service.OtpService;
import com.gym.v2.auth.dto.LoginRequest;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import org.springframework.security.authentication.BadCredentialsException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthenticationServiceTest {

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private RefreshTokenRepository refreshTokenRepository;

	@Mock
	private BlacklistedTokenRepository blacklistedTokenRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private PasswordEncoder passwordEncoder;

	@Mock
	private JwtService jwtService;

	@Mock
	private AuthenticationManager authenticationManager;

	@Mock
	private AuthMapper authMapper;

	@Mock
	private MessageSource messageSource;

	@Mock
	private EncryptionConverter encryptionConverter;

	@Mock
	private OtpService otpService;

	private Clock fixedClock;

	private AuthenticationService authenticationService;

	private static final Instant NOW = Instant.parse("2026-01-01T00:00:00Z");

	@BeforeEach
	void setUp() {
		fixedClock = Clock.fixed(NOW, ZoneOffset.UTC);
		authenticationService = new AuthenticationService(userRepository, refreshTokenRepository,
				blacklistedTokenRepository, coachRepository, clientRepository, passwordEncoder, jwtService,
				authenticationManager, authMapper, messageSource, fixedClock, encryptionConverter, otpService);

		lenient().when(userRepository.saveAndFlush(any(AppUser.class)))
			.thenAnswer(invocation -> invocation.getArgument(0));
	}

	@Test
	void register_adminRole_throwsBadRequestExceptionAndDoesNotSave() {
		RegisterRequest request = RegisterRequestFixture.valid("admin@test.com", UserRole.ADMIN, "+905555555555");

		assertThatThrownBy(() -> authenticationService.register(request)).isInstanceOf(BadRequestException.class);

		verify(userRepository, never()).saveAndFlush(any(AppUser.class));
	}

	@Test
	void register_unnormalizedEmail_looksUpTheNormalizedEmail() {
		RegisterRequest request = RegisterRequestFixture.valid("  Ali@Test.COM  ", UserRole.CLIENT, "+905555555555");

		authenticationService.register(request);

		verify(userRepository).findByEmail("ali@test.com");
	}

	@Test
	void register_unnormalizedEmail_savesNormalizedEmailInUserEntity() {
		RegisterRequest request = RegisterRequestFixture.valid("  Ali@Test.COM  ", UserRole.CLIENT, "+905555555555");

		authenticationService.register(request);

		ArgumentCaptor<AppUser> userCaptor = ArgumentCaptor.forClass(AppUser.class);
		verify(userRepository).saveAndFlush(userCaptor.capture());
		assertThat(userCaptor.getValue().getEmail()).isEqualTo("ali@test.com");
	}

	@Test
	void register_emailAlreadyExists_throwsBadRequestExceptionAndDoesNotSave() {
		RegisterRequest request = RegisterRequestFixture.valid("ali@test.com", UserRole.CLIENT, "+905555555555");
		when(userRepository.findByEmail("ali@test.com")).thenReturn(Optional
			.of(AppUser.builder().email("ali@test.com").role(UserRole.CLIENT).isPhoneVerified(true).build()));

		assertThatThrownBy(() -> authenticationService.register(request)).isInstanceOf(BadRequestException.class);

		verify(userRepository, never()).saveAndFlush(any(AppUser.class));
	}

	@Test
	void register_validRequest_encodesPasswordWithPasswordEncoder() {
		RegisterRequest request = RegisterRequestFixture.valid("ali@test.com", UserRole.CLIENT, "+905555555555");
		when(passwordEncoder.encode("Password123!")).thenReturn("encodedPassword123");

		authenticationService.register(request);

		ArgumentCaptor<AppUser> userCaptor = ArgumentCaptor.forClass(AppUser.class);
		verify(userRepository).saveAndFlush(userCaptor.capture());
		assertThat(userCaptor.getValue().getPassword()).isNotEqualTo("Password123!");
		verify(passwordEncoder).encode("Password123!");
	}

	@Test
	void register_validRequest_setsIsPhoneVerifiedToFalse() {
		RegisterRequest request = RegisterRequestFixture.valid("ali@test.com", UserRole.CLIENT, "+905555555555");

		authenticationService.register(request);

		ArgumentCaptor<AppUser> userCaptor = ArgumentCaptor.forClass(AppUser.class);
		verify(userRepository).saveAndFlush(userCaptor.capture());
		assertThat(userCaptor.getValue().getIsPhoneVerified()).isFalse();
	}

	@Test
	void register_coachRole_savesCoachAndDoesNotSaveClient() {
		RegisterRequest request = RegisterRequestFixture.valid("coach@test.com", UserRole.COACH, "+905555555555");

		authenticationService.register(request);

		verify(coachRepository).save(any());
		verify(clientRepository, never()).save(any());
	}

	@Test
	void register_clientRole_savesClientAndDoesNotSaveCoach() {
		RegisterRequest request = RegisterRequestFixture.valid("client@test.com", UserRole.CLIENT, "+905555555555");

		authenticationService.register(request);

		verify(clientRepository).save(any());
		verify(coachRepository, never()).save(any());
	}

	@Test
	void register_validRequest_passesGeneratedOtpToOtpSimulation() {
		RegisterRequest request = RegisterRequestFixture.valid("client@test.com", UserRole.CLIENT, "+905555555555");
		when(otpService.generateOtp()).thenReturn("654321");

		authenticationService.register(request);

		verify(otpService).sendOtpSimulation(eq("+905555555555"), eq("654321"));
	}

	// ---------------------------------------------------------------------------
	// OTP SERTLEŞTİRMESİ (R4/R5) — kodun süresi, deneme sayacı ve gönderim soğuması
	// ---------------------------------------------------------------------------

	/** OTP bekleyen, telefonu doğrulanmamış bir kullanıcı kurar. */
	private AppUser unverifiedUser(String otpCode, Instant otpExpiresAt, Integer attempts, Instant lastSentAt) {
		AppUser user = AppUser.builder()
			.email("otp@test.com")
			.phoneNumber("+905555555555")
			.role(UserRole.CLIENT)
			.isPhoneVerified(false)
			.otpCode(otpCode)
			.otpExpiresAt(otpExpiresAt)
			.otpLastSentAt(lastSentAt)
			.build();
		user.setOtpAttemptCount(attempts);
		return user;
	}

	@Test
	void register_validRequest_setsOtpExpiryAndLastSentTimestamp() {
		RegisterRequest request = RegisterRequestFixture.valid("client@test.com", UserRole.CLIENT, "+905555555555");

		authenticationService.register(request);

		ArgumentCaptor<AppUser> userCaptor = ArgumentCaptor.forClass(AppUser.class);
		verify(userRepository).saveAndFlush(userCaptor.capture());
		AppUser saved = userCaptor.getValue();
		assertThat(saved.getOtpLastSentAt()).isEqualTo(NOW);
		assertThat(saved.getOtpExpiresAt()).isEqualTo(NOW.plus(5, ChronoUnit.MINUTES));
	}

	@Test
	void verifyOtp_expiredCode_throwsAndInvalidatesCode() {
		AppUser user = unverifiedUser("123456", NOW.minusSeconds(1), 0, NOW.minus(6, ChronoUnit.MINUTES));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.verifyOtp("otp@test.com", "123456"))
			.isInstanceOf(BadRequestException.class);

		assertThat(user.getOtpCode()).isNull();
		assertThat(user.getIsPhoneVerified()).isFalse();
	}

	@Test
	void verifyOtp_wrongCodeBelowLimit_incrementsAttemptCountAndKeepsCode() {
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 1, NOW);
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.verifyOtp("otp@test.com", "999999"))
			.isInstanceOf(BadRequestException.class);

		assertThat(user.getOtpAttemptCount()).isEqualTo(2);
		assertThat(user.getOtpCode()).isEqualTo("123456");
	}

	@Test
	void verifyOtp_wrongCodeAtLimit_invalidatesCodeToStopBruteForce() {
		// 5. hatalı deneme: sayaç 4'ten 5'e çıkar ve sınır aşılır.
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 4, NOW);
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.verifyOtp("otp@test.com", "999999"))
			.isInstanceOf(BadRequestException.class);

		assertThat(user.getOtpCode()).isNull();
		assertThat(user.getOtpAttemptCount()).isZero();
	}

	@Test
	void resendOtp_withinCooldownWindow_throwsBadRequestAndDoesNotSendSms() {
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 0, NOW.minusSeconds(30));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.resendOtp("otp@test.com"))
			.isInstanceOf(BadRequestException.class);

		verify(otpService, never()).sendOtpSimulation(any(), any());
	}

	@Test
	void resendOtp_afterCooldownWindow_issuesFreshOtpAndResetsAttemptCount() {
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 3, NOW.minusSeconds(61));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));
		when(otpService.generateOtp()).thenReturn("777777");

		authenticationService.resendOtp("otp@test.com");

		assertThat(user.getOtpCode()).isEqualTo("777777");
		assertThat(user.getOtpAttemptCount()).isZero();
		assertThat(user.getOtpExpiresAt()).isEqualTo(NOW.plus(5, ChronoUnit.MINUTES));
		verify(otpService).sendOtpSimulation("+905555555555", "777777");
	}

	// ---------------------------------------------------------------------------
	// HESAP KİLİTLEME (R3) — başarısız giriş sayacı gerçekten yazılıyor mu?
	// ---------------------------------------------------------------------------

	@Test
	void login_wrongPasswordBelowLimit_incrementsFailedAttemptsAndDoesNotLock() {
		AppUser user = AppUser.builder().email("lock@test.com").role(UserRole.CLIENT).isPhoneVerified(true).build();
		user.setFailedLoginAttempts(2);
		when(authenticationManager.authenticate(any())).thenThrow(new BadCredentialsException("bad"));
		when(userRepository.findByEmail("lock@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.login(new LoginRequest("lock@test.com", "wrong", "device-1")))
			.isInstanceOf(BadCredentialsException.class);

		assertThat(user.getFailedLoginAttempts()).isEqualTo(3);
		assertThat(user.getAccountLockedUntil()).isNull();
	}

	@Test
	void login_wrongPasswordAtLimit_locksAccountForFifteenMinutes() {
		AppUser user = AppUser.builder().email("lock@test.com").role(UserRole.CLIENT).isPhoneVerified(true).build();
		user.setFailedLoginAttempts(4);
		when(authenticationManager.authenticate(any())).thenThrow(new BadCredentialsException("bad"));
		when(userRepository.findByEmail("lock@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.login(new LoginRequest("lock@test.com", "wrong", "device-1")))
			.isInstanceOf(BadCredentialsException.class);

		assertThat(user.getAccountLockedUntil()).isEqualTo(NOW.plus(15, ChronoUnit.MINUTES));
		assertThat(user.getFailedLoginAttempts()).isZero();
	}

	// ---------------------------------------------------------------------------
	// P1.1 — ŞİFRE SIFIRLAMA YOLU (aynı OTP korumasına tabi olmalı)
	// ---------------------------------------------------------------------------

	@Test
	void forgotPassword_unknownEmail_exitsSilentlyWithoutSendingSms() {
		when(userRepository.findByEmail("yok@test.com")).thenReturn(Optional.empty());

		authenticationService.forgotPassword("yok@test.com");

		// Enumeration koruması: istisna yok, SMS yok, kayıt yok.
		verify(otpService, never()).sendOtpSimulation(any(), any());
		verify(userRepository, never()).save(any());
	}

	@Test
	void forgotPassword_knownEmail_issuesOtpWithExpiryAndResetsAttempts() {
		AppUser user = unverifiedUser(null, null, 3, null);
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));
		when(otpService.generateOtp()).thenReturn("424242");

		authenticationService.forgotPassword("otp@test.com");

		assertThat(user.getOtpCode()).isEqualTo("424242");
		assertThat(user.getOtpExpiresAt()).isEqualTo(NOW.plus(5, ChronoUnit.MINUTES));
		assertThat(user.getOtpAttemptCount()).isZero();
		verify(otpService).sendOtpSimulation("+905555555555", "424242");
	}

	/**
	 * DAVRANIŞ DEĞİŞİKLİĞİ (14.08.2026, H9): soğuma penceresinde artık <b>hata
	 * fırlatılmaz</b>, sessizce çıkılır.
	 * <p>
	 * Eski davranış enumeration korumasını iptal ediyordu: e-posta bulunamadığında metot
	 * sessizce başarı dönerken, bulunduğunda soğuma hatası fırlatıyordu. Aynı adrese arka
	 * arkaya iki istek atan biri, yanıtlardaki bu farktan hangi adreslerin sisteme
	 * kayıtlı olduğunu çıkarabiliyordu.
	 * </p>
	 * <p>
	 * Korumanın <b>asıl amacı</b> — soğuma penceresinde SMS gönderilmemesi — aynen
	 * duruyor ve aşağıda hâlâ doğrulanıyor. Değişen yalnızca çağırana verilen yanıt.
	 * {@code resendOtp} akışında kullanıcının varlığı zaten bilindiği için orada hata
	 * fırlatılmaya devam ediyor.
	 * </p>
	 */
	@Test
	void forgotPassword_withinCooldownWindow_isSilentAndDoesNotSendSms() {
		AppUser user = unverifiedUser("111111", NOW.plus(5, ChronoUnit.MINUTES), 0, NOW.minusSeconds(10));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatCode(() -> authenticationService.forgotPassword("otp@test.com")).doesNotThrowAnyException();

		verify(otpService, never()).sendOtpSimulation(any(), any());
		assertThat(user.getOtpCode()).as("soğuma penceresinde mevcut kod tazelenmemeli").isEqualTo("111111");
	}

	/** Soğuma koruması {@code resendOtp} tarafında hata fırlatmaya devam etmeli. */
	@Test
	void resendOtp_withinCooldownWindow_stillThrows() {
		AppUser user = unverifiedUser("111111", NOW.plus(5, ChronoUnit.MINUTES), 0, NOW.minusSeconds(10));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.resendOtp("otp@test.com"))
			.isInstanceOf(BadRequestException.class);

		verify(otpService, never()).sendOtpSimulation(any(), any());
	}

	@Test
	void resetPassword_expiredCode_throwsAndDoesNotChangePassword() {
		AppUser user = unverifiedUser("123456", NOW.minusSeconds(1), 0, NOW.minus(6, ChronoUnit.MINUTES));
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.resetPassword("otp@test.com", "123456", "YeniSifre123!"))
			.isInstanceOf(BadRequestException.class);

		assertThat(user.getOtpCode()).isNull();
		verify(passwordEncoder, never()).encode(any());
	}

	@Test
	void resetPassword_wrongCode_incrementsAttemptCountAndDoesNotChangePassword() {
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 1, NOW);
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));

		assertThatThrownBy(() -> authenticationService.resetPassword("otp@test.com", "999999", "YeniSifre123!"))
			.isInstanceOf(BadRequestException.class);

		assertThat(user.getOtpAttemptCount()).isEqualTo(2);
		verify(passwordEncoder, never()).encode(any());
	}

	@Test
	void resetPassword_validCode_encodesNewPasswordAndClearsOtp() {
		AppUser user = unverifiedUser("123456", NOW.plus(5, ChronoUnit.MINUTES), 0, NOW);
		when(userRepository.findByEmail("otp@test.com")).thenReturn(Optional.of(user));
		when(passwordEncoder.encode("YeniSifre123!")).thenReturn("hashed");

		authenticationService.resetPassword("otp@test.com", "123456", "YeniSifre123!");

		assertThat(user.getPassword()).isEqualTo("hashed");
		assertThat(user.getOtpCode()).isNull();
		assertThat(user.getOtpExpiresAt()).isNull();
	}

	// ---------------------------------------------------------------------------
	// P1.1 — OTURUM YAŞAM DÖNGÜSÜ: refreshToken / logout
	// ---------------------------------------------------------------------------

	private RefreshToken refreshTokenOf(AppUser user, String token, String deviceId, Instant expiry) {
		RefreshToken rt = new RefreshToken();
		rt.setUser(user);
		rt.setToken(token);
		rt.setDeviceId(deviceId);
		rt.setExpiryDate(expiry);
		return rt;
	}

	@Test
	void refreshToken_unknownToken_throwsBadRequest() {
		when(refreshTokenRepository.findByToken("yok")).thenReturn(Optional.empty());

		assertThatThrownBy(() -> authenticationService.refreshToken("yok", "device-1"))
			.isInstanceOf(BadRequestException.class);
	}

	@Test
	void refreshToken_deviceIdMismatch_throwsSecurityExceptionAndDoesNotDelete() {
		AppUser user = AppUser.builder().email("rt@test.com").role(UserRole.CLIENT).build();
		RefreshToken rt = refreshTokenOf(user, "tok", "device-A", NOW.plus(7, ChronoUnit.DAYS));
		when(refreshTokenRepository.findByToken("tok")).thenReturn(Optional.of(rt));

		assertThatThrownBy(() -> authenticationService.refreshToken("tok", "device-B"))
			.isInstanceOf(SecurityException.class);

		verify(refreshTokenRepository, never()).delete(any());
	}

	@Test
	void refreshToken_expiredToken_deletesTokenAndThrows() {
		AppUser user = AppUser.builder().email("rt@test.com").role(UserRole.CLIENT).build();
		RefreshToken rt = refreshTokenOf(user, "tok", "device-1", NOW.minusSeconds(1));
		when(refreshTokenRepository.findByToken("tok")).thenReturn(Optional.of(rt));

		assertThatThrownBy(() -> authenticationService.refreshToken("tok", "device-1"))
			.isInstanceOf(BadRequestException.class);

		verify(refreshTokenRepository).delete(rt);
	}

	@Test
	void refreshToken_validToken_rotatesTokenAndDeletesOldOne() {
		AppUser user = AppUser.builder().email("rt@test.com").role(UserRole.CLIENT).build();
		RefreshToken rt = refreshTokenOf(user, "eski", "device-1", NOW.plus(7, ChronoUnit.DAYS));
		when(refreshTokenRepository.findByToken("eski")).thenReturn(Optional.of(rt));
		when(refreshTokenRepository.save(any(RefreshToken.class))).thenAnswer(inv -> inv.getArgument(0));

		authenticationService.refreshToken("eski", "device-1");

		// Yenileme sonrası eski token mutlaka silinmeli (rotation).
		verify(refreshTokenRepository).delete(rt);
		ArgumentCaptor<RefreshToken> captor = ArgumentCaptor.forClass(RefreshToken.class);
		verify(refreshTokenRepository).save(captor.capture());
		assertThat(captor.getValue().getToken()).isNotEqualTo("eski");
		assertThat(captor.getValue().getDeviceId()).isEqualTo("device-1");
	}

	@Test
	void logout_blacklistsTokenIdAndRemovesAllRefreshTokens() {
		AppUser user = AppUser.builder().email("out@test.com").role(UserRole.CLIENT).build();
		when(jwtService.extractJti("access-token")).thenReturn("jti-123");
		when(userRepository.findByEmail("out@test.com")).thenReturn(Optional.of(user));

		authenticationService.logout("access-token", "out@test.com");

		verify(blacklistedTokenRepository).save(any());
		verify(refreshTokenRepository).deleteAllByUser(user);
	}

	// ---------------------------------------------------------------------------
	// DAVRANIŞ DEĞİŞİKLİĞİ (H11): /auth/cancel-registration ucu KALDIRILDI.
	// Kimlik doğrulaması istemiyordu; e-postayı bilen biri OTP ekranında bekleyen bir
	// kaydı silip kişinin kaydolmasını engelleyebiliyordu. OTP kanıtı istemek geri çıkış
	// akışını kırardı (kullanıcı kodu almadığı için çıkıyor). Yerine `register` aynı
	// e-postalı DOĞRULANMAMIŞ kaydın yerine geçiyor; uç gereksizleşti ve silindi.
	// ---------------------------------------------------------------------------

	@Test
	void register_replacesAnExistingUnverifiedRegistrationWithTheSameEmail() {
		AppUser pending = AppUser.builder()
			.email("gecici@test.com")
			.role(UserRole.CLIENT)
			.isPhoneVerified(false)
			.build();
		when(userRepository.findByEmail("gecici@test.com")).thenReturn(Optional.of(pending));
		when(clientRepository.findByUserId(any())).thenReturn(Optional.empty());

		authenticationService
			.register(RegisterRequestFixture.valid("gecici@test.com", UserRole.CLIENT, "+905555555555"));

		verify(userRepository).delete(pending);
		verify(userRepository, atLeastOnce()).saveAndFlush(any(AppUser.class));
	}

	@Test
	void register_doesNotTouchAVerifiedAccountWithTheSameEmail() {
		AppUser verified = AppUser.builder().email("var@test.com").role(UserRole.CLIENT).isPhoneVerified(true).build();
		when(userRepository.findByEmail("var@test.com")).thenReturn(Optional.of(verified));

		assertThatThrownBy(() -> authenticationService
			.register(RegisterRequestFixture.valid("var@test.com", UserRole.CLIENT, "+905555555555")))
			.isInstanceOf(BadRequestException.class);

		// Doğrulanmış gerçek hesap hiçbir koşulda silinmez.
		verify(userRepository, never()).delete(any());
	}

	@Test
	void login_unknownEmail_doesNotThrowSecondaryErrorFromLockoutBookkeeping() {
		when(authenticationManager.authenticate(any())).thenThrow(new BadCredentialsException("bad"));
		when(userRepository.findByEmail("yok@test.com")).thenReturn(Optional.empty());

		// Kullanıcı sıralama (enumeration) sızıntısı olmaması için davranış aynı kalmalı.
		assertThatThrownBy(() -> authenticationService.login(new LoginRequest("yok@test.com", "wrong", "device-1")))
			.isInstanceOf(BadCredentialsException.class);
	}

}
