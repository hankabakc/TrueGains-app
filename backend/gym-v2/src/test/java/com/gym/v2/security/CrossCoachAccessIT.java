package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Antrenörler arası veri izolasyonu (IDOR) testleri.
 * <p>
 * Kritik nokta: sorgulanan uçlar sporcu/antrenör kimliğini <b>URL yolundan</b> alır. Bu
 * nedenle sahiplik kontrolünün servis katmanında yapıldığı doğrulanmalıdır; yalnızca rol
 * kontrolü (COACH olmak) yeterli değildir.
 * </p>
 */
class CrossCoachAccessIT extends IntegrationTestBase {

	private AppUser coachA;

	private AppUser coachB;

	private AppUser clientUser;

	/**
	 * Koç A'ya bağlı bir sporcu kurar. {@code clientId} yol değişkeni sporcunun
	 * <b>kullanıcı</b> id'sidir ({@code MeasurementService} {@code findByUserId} ile
	 * arar).
	 */
	private void setUpCoachesAndClient() {
		coachA = createUser("coachA@test.com", UserRole.COACH);
		coachB = createUser("coachB@test.com", UserRole.COACH);
		clientUser = createUser("clientA@test.com", UserRole.CLIENT);

		ClientEntity clientEntity = new ClientEntity();
		clientEntity.setUser(clientUser);
		clientEntity.setFullName("Client A");
		clientEntity.setCoachId(coachA.getId());
		clientRepository.saveAndFlush(clientEntity);
	}

	@Test
	void getSharedMeasurementsForClient_ownCoach_returnsOk() throws Exception {
		setUpCoachesAndClient();

		mockMvc.perform(get("/api/v1/coaches/measurements/shared/" + clientUser.getId()).header("Authorization",
				bearerTokenFor(coachA)))
			.andExpect(status().isOk());
	}

	@Test
	void getSharedMeasurementsForClient_foreignCoach_returnsForbidden() throws Exception {
		setUpCoachesAndClient();

		mockMvc.perform(get("/api/v1/coaches/measurements/shared/" + clientUser.getId()).header("Authorization",
				bearerTokenFor(coachB)))
			.andExpect(status().isForbidden());
	}

	/**
	 * Sporcu profili yanıtı e-posta, doğum tarihi ve vücut ölçülerini şifresi çözülmüş
	 * hâlde döndürür; COACH rolü tek başına yeterli olamaz.
	 */
	@Test
	void getClientProfile_ownCoach_returnsOk() throws Exception {
		setUpCoachesAndClient();

		mockMvc
			.perform(
					get("/api/v1/profile/client/" + clientUser.getId()).header("Authorization", bearerTokenFor(coachA)))
			.andExpect(status().isOk());
	}

	@Test
	void getClientProfile_foreignCoach_returnsForbidden() throws Exception {
		setUpCoachesAndClient();

		mockMvc
			.perform(
					get("/api/v1/profile/client/" + clientUser.getId()).header("Authorization", bearerTokenFor(coachB)))
			.andExpect(status().isForbidden());
	}

	@Test
	void getApprovedProgress_foreignCoach_returnsForbidden() throws Exception {
		setUpCoachesAndClient();

		mockMvc.perform(get("/api/v1/coaches/progress/coach/" + coachA.getId() + "/approved").header("Authorization",
				bearerTokenFor(coachB)))
			.andExpect(status().isForbidden());
	}

}
