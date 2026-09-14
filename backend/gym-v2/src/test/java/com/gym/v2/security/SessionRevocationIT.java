package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.BlacklistedToken;
import com.gym.v2.auth.dto.LoginRequest;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.auth.service.AuthenticationService;
import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.core.security.interceptor.JwtChannelInterceptor;
import com.gym.v2.membership.dto.ChangePasswordRequest;
import com.gym.v2.membership.service.ProfileService;
import com.gym.v2.support.IntegrationTestBase;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Oturum sonlandırmanın gerçekten her kanalı kapattığını doğrular.
 * <p>
 * "Çıkış yaptım" ve "şifremi değiştirdim" ifadelerinin ikisi de kullanıcı için aynı şeyi
 * vaat eder: eski oturum artık geçerli değil. Bu testler o vaadin HTTP dışındaki
 * kanallarda da tutulduğunu kontrol eder.
 * </p>
 */
class SessionRevocationIT extends IntegrationTestBase {

	@Autowired
	private JwtChannelInterceptor channelInterceptor;

	@Autowired
	private BlacklistedTokenRepository blacklistedTokenRepository;

	@Autowired
	private RefreshTokenRepository refreshTokenRepository;

	@Autowired
	private AuthenticationService authenticationService;

	@Autowired
	private ProfileService profileService;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	/**
	 * Elindeki token'la WebSocket bağlantısı açmaya çalışan bir istemciyi taklit eder.
	 */
	private Message<byte[]> connectFrameWith(String rawToken) {
		StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECT);
		accessor.setNativeHeader(SecurityConstants.AUTH_HEADER, "Bearer " + rawToken);
		accessor.setLeaveMutable(true);
		return org.springframework.messaging.support.MessageBuilder.createMessage(new byte[0],
				accessor.getMessageHeaders());
	}

	@Test
	void validToken_canOpenAWebSocketConnection() {
		AppUser user = createUser("ws_valid@test.com", UserRole.CLIENT);
		String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());

		assertThat(channelInterceptor.preSend(connectFrameWith(token), null))
			.as("ön koşul: geçerli token bağlanabilmeli, aksi hâlde asıl test bir şey kanıtlamaz")
			.isNotNull();
	}

	@Test
	void blacklistedToken_cannotOpenAWebSocketConnection() {
		AppUser user = createUser("ws_logout@test.com", UserRole.CLIENT);
		String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());

		// Kullanıcı çıkış yapar: token'ın jti'si kara listeye alınır.
		String jti = jwtService.extractJti(token);
		blacklistedTokenRepository.saveAndFlush(new BlacklistedToken(jti, Instant.now().plus(24, ChronoUnit.HOURS)));

		assertThatThrownBy(() -> channelInterceptor.preSend(connectFrameWith(token), null))
			.as("çıkış yapılmış token'la sohbete bağlanılabiliyor; kara liste yalnızca HTTP'de kontrol ediliyor")
			.isInstanceOf(MessageDeliveryException.class);
	}

	@Test
	void resettingPassword_revokesEveryRefreshToken() {
		AppUser user = createUser("reset_revoke@test.com", UserRole.CLIENT);
		loginAs(user);
		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(user))
			.as("ön koşul: girişten sonra yenileme token'ı oluşmalı")
			.isNotEmpty();

		// Kullanıcı OTP alıp şifresini sıfırlar.
		authenticationService.forgotPassword(user.getEmail());
		String otp = userRepository.findByEmail(user.getEmail()).orElseThrow().getOtpCode();
		authenticationService.resetPassword(user.getEmail(), otp, "YeniSifre123!");

		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(user))
			.as("şifre sıfırlandı; saldırganın yenileme token'ı hâlâ geçerliyse şifre değiştirmek onu atmıyor")
			.isEmpty();
	}

	@Test
	void changingPassword_revokesEveryRefreshToken() {
		AppUser user = createUser("change_revoke@test.com", UserRole.CLIENT);
		loginAs(user);
		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(user)).isNotEmpty();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		profileService.changePassword(new ChangePasswordRequest("Password123!", "YeniSifre123!"));

		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(user))
			.as("profil ekranından şifre değiştirmek de tüm oturumları kapatmalı")
			.isEmpty();
	}

	@Test
	void forgotPassword_answersTheSameWhetherTheEmailExistsOrNot() {
		AppUser user = createUser("enum_probe@test.com", UserRole.CLIENT);

		// Kayıtlı adrese arka arkaya iki istek: ikincisi soğuma süresine takılır.
		authenticationService.forgotPassword(user.getEmail());

		assertThatCode(() -> authenticationService.forgotPassword(user.getEmail()))
			.as("kayıtlı adres soğuma hatası, kayıtsız adres sessiz başarı dönerse "
					+ "saldırgan hangi e-postaların sisteme kayıtlı olduğunu tarayabilir")
			.doesNotThrowAnyException();

		// Kayıtsız adres zaten sessizce başarı döner; iki dal artık ayırt edilemez.
		assertThatCode(() -> authenticationService.forgotPassword("hicyok@test.com")).doesNotThrowAnyException();
	}

	private void loginAs(AppUser user) {
		authenticationService
			.login(new LoginRequest(user.getEmail(), "Password123!", SecurityConstants.DEFAULT_DEVICE_ID));
	}

}
