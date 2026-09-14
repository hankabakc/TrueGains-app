package com.gym.v2.auth;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

/**
 * Telefon doğrulama kapısının <b>kime</b> uygulandığı.
 * <p>
 * Bu kapı tüketici KAYIT akışının parçası: kullanıcı kendi numarasını girer ve
 * sahipliğini kanıtlar. Yönetici hesapları o akıştan geçmez — {@code register} ADMIN
 * rolünü reddediyor, hesap migrasyonla sağlanıyor ve numarası yok. Kapıyı onlara
 * uygulamak "doğrulanacak bir şey olmadığı için asla doğrulanamaz" demek, yani kalıcı
 * kilit.
 * </p>
 * <p>
 * Bu sınıfın asıl işi kapının <b>gevşemediğini</b> kanıtlamak: CLIENT ve COACH için
 * davranış birebir aynı kalmalı.
 * </p>
 */
class AuthPhoneGateIT extends IntegrationTestBase {

	/**
	 * {@code IntegrationTestBase.createUser} telefonu doğrulanmış kurar; burada tersi
	 * lazım.
	 */
	private AppUser unverifiedUser(String email, UserRole role) {
		AppUser user = AppUser.builder()
			.email(email)
			.password(passwordEncoder.encode("Password123!"))
			.role(role)
			.registeredAt(Instant.parse("2026-01-01T00:00:00Z"))
			.phoneNumber("+90555" + Math.abs(email.hashCode() % 10000000))
			.isPhoneVerified(false)
			.build();
		return userRepository.saveAndFlush(user);
	}

	private org.springframework.test.web.servlet.ResultActions login(String email) throws Exception {
		return mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/auth/login")
			.contentType(MediaType.APPLICATION_JSON)
			.content("{\"email\":\"" + email + "\",\"password\":\"Password123!\",\"deviceId\":\"test-device\"}")
			.with(csrf()));
	}

	/**
	 * REGRESYON KİLİDİ: sporcunun telefonu doğrulanmamışsa oturum açılamaz. Bu davranış
	 * ADMIN muafiyeti eklenirken değişmemeli.
	 */
	@Test
	void client_withUnverifiedPhone_isStillBlocked() throws Exception {
		unverifiedUser("sporcu-dogrulanmamis@test.com", UserRole.CLIENT);

		login("sporcu-dogrulanmamis@test.com").andExpect(MockMvcResultMatchers.status().isForbidden());
	}

	/** Aynı kural antrenör için de aynen geçerli. */
	@Test
	void coach_withUnverifiedPhone_isStillBlocked() throws Exception {
		unverifiedUser("antrenor-dogrulanmamis@test.com", UserRole.COACH);

		login("antrenor-dogrulanmamis@test.com").andExpect(MockMvcResultMatchers.status().isForbidden());
	}

	/**
	 * Yönetici, numarası doğrulanmamış olsa da girebilmeli — aksi hâlde migrasyonla
	 * sağlanan hesap hiçbir zaman açılamaz.
	 */
	@Test
	void admin_withUnverifiedPhone_canSignIn() throws Exception {
		unverifiedUser("yonetici-dogrulanmamis@test.com", UserRole.ADMIN);

		login("yonetici-dogrulanmamis@test.com").andExpect(MockMvcResultMatchers.status().isOk())
			.andExpect(MockMvcResultMatchers.jsonPath("$.data.access_token").exists())
			.andExpect(MockMvcResultMatchers.jsonPath("$.data.user.role").value("ADMIN"));
	}

	/** Doğrulanmış tüketici hesabı elbette girebilmeli; kapı yanlış tarafa kapanmasın. */
	@Test
	void client_withVerifiedPhone_canSignIn() throws Exception {
		createUser("sporcu-dogrulanmis@test.com", UserRole.CLIENT);

		login("sporcu-dogrulanmis@test.com").andExpect(MockMvcResultMatchers.status().isOk())
			.andExpect(MockMvcResultMatchers.jsonPath("$.data.access_token").exists());
	}

}
