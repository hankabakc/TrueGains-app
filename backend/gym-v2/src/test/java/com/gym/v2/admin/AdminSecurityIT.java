package com.gym.v2.admin;

import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Yonetim paneli yetkilendirmesi.
 * <p>
 * {@code UserRole.ADMIN} enum'da bastan beri vardi ama HICBIR uc onu kontrol etmiyordu;
 * admin hesabinin fiilen hicbir ayricaligi yoktu. Bu sinif o kuralin gercekten
 * uygulandigini ve sporcunun/antrenorun panele giremedigini kilitler.
 * </p>
 */
class AdminSecurityIT extends IntegrationTestBase {

	private static final String OVERVIEW = "/api/v1/admin/overview";

	/**
	 * Modulun BUTUN okuma uclari. Yetki kurali yola bagli oldugu icin buraya eklenen her
	 * yeni yol otomatik korunmali; liste o guvenceyi tek tek kanitliyor.
	 */
	private static final java.util.List<String> READ_ENDPOINTS = java.util.List.of("/api/v1/admin/overview",
			"/api/v1/admin/system", "/api/v1/admin/errors", "/api/v1/admin/users", "/api/v1/admin/users/export",
			"/api/v1/admin/finance/revenue", "/api/v1/admin/finance/payments", "/api/v1/admin/audit",
			"/api/v1/admin/audit/actions", "/api/v1/admin/reports");

	/**
	 * Kimlik dogrulamasi olmayan istek 401 DEGIL 403 aliyor: bu uygulamanin mevcut
	 * davranisi (giris noktasi 403 donuyor). Test o davranisi oldugu gibi kaydediyor.
	 */
	@Test
	void overview_withoutAuthentication_isRejected() throws Exception {
		mockMvc.perform(get(OVERVIEW)).andExpect(status().isForbidden());
	}

	@Test
	void overview_asClient_isForbidden() throws Exception {
		mockMvc.perform(get(OVERVIEW).with(user("sporcu@test.com").roles("CLIENT"))).andExpect(status().isForbidden());
	}

	@Test
	void overview_asCoach_isForbidden() throws Exception {
		mockMvc.perform(get(OVERVIEW).with(user("antrenor@test.com").roles("COACH"))).andExpect(status().isForbidden());
	}

	/**
	 * Yetki kurali yola bagli; module eklenen HER yeni uc otomatik korunmali. Sistem ucu
	 * bunu dogruluyor.
	 */
	@Test
	void system_asCoach_isForbidden() throws Exception {
		mockMvc.perform(get("/api/v1/admin/system").with(user("antrenor@test.com").roles("COACH")))
			.andExpect(status().isForbidden());
	}

	@Test
	void system_asAdmin_returnsRuntimeNumbers() throws Exception {
		mockMvc.perform(get("/api/v1/admin/system").with(user("admin@test.com").roles("ADMIN")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.uptimeSeconds").exists())
			.andExpect(jsonPath("$.data.heapMaxBytes").exists())
			.andExpect(jsonPath("$.data.dbMax").exists());
	}

	@Test
	void overview_asAdmin_returnsCounts() throws Exception {
		mockMvc.perform(get(OVERVIEW).with(user("admin@test.com").roles("ADMIN")))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalUsers").exists())
			.andExpect(jsonPath("$.data.coachCount").exists())
			.andExpect(jsonPath("$.data.activeSubscriptions").exists());
	}

	@Test
	void everyReadEndpoint_withoutAuthentication_isRejected() throws Exception {
		for (String endpoint : READ_ENDPOINTS) {
			mockMvc.perform(get(endpoint)).andExpect(status().isForbidden());
		}
	}

	@Test
	void everyReadEndpoint_asClient_isForbidden() throws Exception {
		for (String endpoint : READ_ENDPOINTS) {
			mockMvc.perform(get(endpoint).with(user("sporcu@test.com").roles("CLIENT")))
				.andExpect(status().isForbidden());
		}
	}

	@Test
	void everyReadEndpoint_asAdmin_isReachable() throws Exception {
		for (String endpoint : READ_ENDPOINTS) {
			mockMvc.perform(get(endpoint).with(user("admin@test.com").roles("ADMIN"))).andExpect(status().isOk());
		}
	}

	/**
	 * Yazma uclari da ayni kurala tabi. Sporcu bir hesabi pasiflestirememeli - bu,
	 * modulun en tehlikeli ucu.
	 */
	@Test
	void deactivateUser_asClient_isForbidden() throws Exception {
		mockMvc
			.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
				.patch("/api/v1/admin/users/1/active")
				.param("value", "false")
				.with(user("sporcu@test.com").roles("CLIENT"))
				.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
					.csrf()))
			.andExpect(status().isForbidden());
	}

	@Test
	void resolveReport_asCoach_isForbidden() throws Exception {
		mockMvc
			.perform(
					org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch("/api/v1/admin/reports/1")
						.contentType(org.springframework.http.MediaType.APPLICATION_JSON)
						.content("{\"decision\":\"DISMISSED\"}")
						.with(user("antrenor@test.com").roles("COACH"))
						.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
							.csrf()))
			.andExpect(status().isForbidden());
	}

	@Test
	void unlockUser_asClient_isForbidden() throws Exception {
		mockMvc
			.perform(patch("/api/v1/admin/users/1/unlock").with(user("sporcu@test.com").roles("CLIENT")).with(csrf()))
			.andExpect(status().isForbidden());
	}

}
