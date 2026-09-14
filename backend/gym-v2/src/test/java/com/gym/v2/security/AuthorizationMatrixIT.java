package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthorizationMatrixIT extends IntegrationTestBase {

	@Test
	void getSharedMeasurements_noAuthHeader_returnsForbidden() throws Exception {
		mockMvc.perform(get("/api/v1/coaches/measurements/shared")).andExpect(status().isForbidden());
	}

	@Test
	void getSharedMeasurements_clientToken_returnsForbidden() throws Exception {
		AppUser client = createUser("client@matrix.com", UserRole.CLIENT);

		mockMvc.perform(get("/api/v1/coaches/measurements/shared").header("Authorization", bearerTokenFor(client)))
			.andExpect(status().isForbidden());
	}

	@Test
	void getSharedMeasurements_coachToken_returnsOk() throws Exception {
		AppUser coach = createUser("coach@matrix.com", UserRole.COACH);

		mockMvc.perform(get("/api/v1/coaches/measurements/shared").header("Authorization", bearerTokenFor(coach)))
			.andExpect(status().isOk());
	}

	@Test
	void getSharedMeasurements_invalidToken_returnsUnauthorized() throws Exception {
		mockMvc
			.perform(get("/api/v1/coaches/measurements/shared").header("Authorization", "Bearer invalid.token.value"))
			.andExpect(status().isUnauthorized());
	}

	/**
	 * Ödeme bildirimi aboneliği aktifleştirir; kimliksiz çağrılabilirse herkes kendine
	 * ücretli paket açabilir.
	 */
	@Test
	void paymentWebhook_noAuthHeader_returnsForbidden() throws Exception {
		mockMvc
			.perform(post("/api/v1/webhooks/payment").contentType(MediaType.APPLICATION_JSON)
				.content("{\"sessionId\":\"mock_sess_deneme\",\"status\":\"SUCCESS\"}"))
			.andExpect(status().isForbidden());
	}

	/**
	 * Simülasyon ucu ödeme sonucunu belirler; kimliksiz çağrılabilirse webhook'taki
	 * korumanın bir anlamı kalmaz.
	 */
	@Test
	void mockGateway_noAuthHeader_returnsForbidden() throws Exception {
		mockMvc.perform(post("/api/v1/mock-gateway/pay/mock_sess_deneme/SUCCESS")).andExpect(status().isForbidden());
	}

	@Test
	void paymentWebhook_authenticated_reachesTheHandler() throws Exception {
		AppUser client = createUser("webhook_client@matrix.com", UserRole.CLIENT);

		// Bilinmeyen oturum kimliği: istek güvenlik katmanını geçip iş mantığına ulaşır.
		mockMvc
			.perform(post("/api/v1/webhooks/payment").header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content("{\"sessionId\":\"mock_sess_yok\",\"status\":\"SUCCESS\"}"))
			.andExpect(status().isNotFound());
	}

}
