package com.gym.v2.auth;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.service.LogService;
import com.gym.v2.support.IntegrationTestBase;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

/**
 * Giriş başarısızlığı ve hesap durumlarının (kilitli/pasif hesap, doğrulanmamış telefon)
 * doğru HTTP durum kodları ve mesajlarla ele alındığını; tasarlanmış durumlarda Sentry'ye
 * hata raporlanmadığını doğrulayan entegrasyon testleri (L1-L6).
 */
class AuthLoginFailureIT extends IntegrationTestBase {

	@MockitoBean
	private LogService logService;

	private AppUser user(String email, boolean phoneVerified, boolean active, Instant lockedUntil) {
		AppUser appUser = AppUser.builder()
			.email(email)
			.password(passwordEncoder.encode("Password123!"))
			.role(UserRole.CLIENT)
			.registeredAt(Instant.parse("2026-01-01T00:00:00Z"))
			.phoneNumber("+90555" + String.format("%07d", Math.abs(email.hashCode() % 10000000)))
			.isPhoneVerified(phoneVerified)
			.isActive(active)
			.accountLockedUntil(lockedUntil)
			.build();
		return userRepository.saveAndFlush(appUser);
	}

	private ResultActions login(String email, String password) throws Exception {
		return mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/auth/login")
			.contentType(MediaType.APPLICATION_JSON)
			.content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\",\"deviceId\":\"test-device\"}")
			.with(csrf()));
	}

	/**
	 * L1: Kilitli hesaba yanlış şifreyle girildiğinde hesap durumu sızdırılmaz; genel 401
	 * kimlik doğrulama hatası döner.
	 */
	@Test
	void lockedAccount_wrongPassword_getsGenericMessage() throws Exception {
		user("kilitli-yanlis@test.com", true, true, Instant.parse("2099-01-01T00:00:00Z"));

		login("kilitli-yanlis@test.com", "YanlisSifre123!").andExpect(MockMvcResultMatchers.status().isUnauthorized())
			.andExpect(MockMvcResultMatchers.jsonPath("$.message").value("Geçersiz e-posta veya şifre."));
	}

	/**
	 * L2: Kilitli hesaba doğru şifreyle girildiğinde 401 ve özel kilit mesajı döner;
	 * tasarlanmış durum olduğu için Sentry'ye log.error basılmaz.
	 */
	@Test
	void lockedAccount_correctPassword_getsLockedMessage() throws Exception {
		user("kilitli-dogru@test.com", true, true, Instant.parse("2099-01-01T00:00:00Z"));

		login("kilitli-dogru@test.com", "Password123!").andExpect(MockMvcResultMatchers.status().isUnauthorized())
			.andExpect(MockMvcResultMatchers.jsonPath("$.message")
				.value("Hesabınız çok sayıda hatalı giriş nedeniyle geçici olarak kilitlendi. En geç 15 dakika sonra tekrar deneyin."));

		verify(logService, never()).error(any());
	}

	/**
	 * L3: Pasif hesaba yanlış şifreyle girildiğinde hesap durumu sızdırılmaz; genel 401
	 * kimlik doğrulama hatası döner.
	 */
	@Test
	void disabledAccount_wrongPassword_getsGenericMessage() throws Exception {
		user("pasif-yanlis@test.com", true, false, null);

		login("pasif-yanlis@test.com", "YanlisSifre123!").andExpect(MockMvcResultMatchers.status().isUnauthorized())
			.andExpect(MockMvcResultMatchers.jsonPath("$.message").value("Geçersiz e-posta veya şifre."));
	}

	/**
	 * L4: Pasif hesaba doğru şifreyle girildiğinde 401 ve hesap kapatıldı mesajı döner;
	 * Sentry'ye log.error basılmaz.
	 */
	@Test
	void disabledAccount_correctPassword_getsDisabledMessage() throws Exception {
		user("pasif-dogru@test.com", true, false, null);

		login("pasif-dogru@test.com", "Password123!").andExpect(MockMvcResultMatchers.status().isUnauthorized())
			.andExpect(MockMvcResultMatchers.jsonPath("$.message")
				.value("Hesabınız kapatılmış. Bilgi almak için destek ile iletişime geçin."));

		verify(logService, never()).error(any());
	}

	/**
	 * L5: Telefonu doğrulanmamış hesaba doğru şifreyle girildiğinde 403 döner;
	 * tasarlanmış akış olduğundan Sentry'ye log.error basılmaz.
	 */
	@Test
	void unverifiedPhone_isNotReportedToSentry() throws Exception {
		user("telefon-dogrulanmamis@test.com", false, true, null);

		login("telefon-dogrulanmamis@test.com", "Password123!").andExpect(MockMvcResultMatchers.status().isForbidden());

		verify(logService, never()).error(any());
	}

	/**
	 * L6: Telefonu doğrulanmamış hesapla giriş denendiğinde yeni OTP kodu veritabanına
	 * yazılır (noRollbackFor sayesinde geri alınmaz) ve lastLoginAt güncellenmez.
	 */
	@Test
	@Transactional(propagation = Propagation.NOT_SUPPORTED)
	void unverifiedPhone_newOtpIsPersisted_lastLoginNotWritten() throws Exception {
		AppUser createdUser = user("otp-kalicilik@test.com", false, true, null);
		Long userId = createdUser.getId();

		try {
			login("otp-kalicilik@test.com", "Password123!").andExpect(MockMvcResultMatchers.status().isForbidden());

			AppUser updatedUser = userRepository.findById(userId).orElseThrow();
			assertThat(updatedUser.getOtpCode()).isNotNull();
			assertThat(updatedUser.getOtpLastSentAt()).isNotNull();
			assertThat(updatedUser.getLastLoginAt()).isNull();
		}
		finally {
			userRepository.deleteById(userId);
		}
	}

}
