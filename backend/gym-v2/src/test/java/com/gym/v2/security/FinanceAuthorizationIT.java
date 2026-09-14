package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Para uçlarının rol bazlı yetkilendirme matrisi.
 * <p>
 * Mevcut {@code FinanceControllerTest} standalone MockMvc kullanır ve Spring Security
 * filtre zincirini yüklemez; yani {@code @PreAuthorize} kurallarını <b>hiç</b>
 * doğrulamaz. Bu sınıf gerçek zinciri yükleyerek her ucun doğru rolle korunduğunu
 * kanıtlar.
 * </p>
 * <p>
 * <b>Neden önemli:</b> G1 bulgusunda {@code @EnableMethodSecurity} eksikti ve bu 40+
 * kural sessizce etkisizdi. Aynı hatanın para uçlarında tekrarlanması, bir sporcunun koç
 * paketlerini silmesi ya da bir koçun başkasının sepetini boşaltması demek olurdu.
 * </p>
 */
class FinanceAuthorizationIT extends IntegrationTestBase {

	/** Bean Validation kurallarının tamamını geçen paket gövdesi. */
	private static final String VALID_PACKAGE_JSON = """
			{
			  "name": "Standard",
			  "price": 150.00,
			  "durationDays": 30,
			  "description": "Aylik paket",
			  "features": "Haftalik program",
			  "quota": 5,
			  "levels": "BASLANGIC",
			  "mode": "ONLINE"
			}
			""";

	private String clientToken() {
		return bearerTokenFor(createUser("finance_client@test.com", UserRole.CLIENT));
	}

	private String coachToken() {
		return bearerTokenFor(createUser("finance_coach@test.com", UserRole.COACH));
	}

	/** Yetkisi olmayan rolün 403 aldığını doğrular. */
	private void expectForbidden(MockHttpServletRequestBuilder request, String token) throws Exception {
		mockMvc.perform(request.header("Authorization", token).contentType(MediaType.APPLICATION_JSON))
			.andExpect(status().isForbidden());
	}

	// ---------------------------------------------------------------------------
	// Koça özel uçlar — sporcu erişemez
	// ---------------------------------------------------------------------------

	@Test
	void coachOnlyEndpoints_areForbiddenForClients() throws Exception {
		String token = clientToken();

		expectForbidden(get("/api/v1/finance/coach/packages"), token);
		// Gövde GEÇERLİ olmalı: @Valid doğrulaması @PreAuthorize'dan önce çalışır ve
		// geçersiz gövdede 403 yerine 400 döner (aşağıdaki nota bakın).
		expectForbidden(post("/api/v1/finance/coach/packages").content(VALID_PACKAGE_JSON), token);
		expectForbidden(delete("/api/v1/finance/coach/packages/1"), token);
		expectForbidden(get("/api/v1/finance/coach/subscription/1"), token);
		expectForbidden(get("/api/v1/finance/coach/dashboard-stats"), token);
	}

	// ---------------------------------------------------------------------------
	// Sporcuya özel uçlar — koç erişemez
	// ---------------------------------------------------------------------------

	@Test
	void clientOnlyEndpoints_areForbiddenForCoaches() throws Exception {
		String token = coachToken();

		expectForbidden(post("/api/v1/finance/cart/add/1"), token);
		expectForbidden(delete("/api/v1/finance/cart/cancel/1"), token);
		expectForbidden(get("/api/v1/finance/transactions"), token);
		expectForbidden(get("/api/v1/finance/my-subscription"), token);
		expectForbidden(get("/api/v1/finance/purchase-intent/1"), token);
		expectForbidden(get("/api/v1/finance/packages/1"), token);
	}

	// ---------------------------------------------------------------------------
	// Kimliksiz erişim — hiçbir para ucu açık olmamalı
	// ---------------------------------------------------------------------------

	@Test
	void financeEndpoints_rejectUnauthenticatedRequests() throws Exception {
		mockMvc.perform(get("/api/v1/finance/transactions")).andExpect(status().isForbidden());
		mockMvc.perform(get("/api/v1/finance/coach/packages")).andExpect(status().isForbidden());
		mockMvc.perform(post("/api/v1/finance/cart/add/1").contentType(MediaType.APPLICATION_JSON))
			.andExpect(status().isForbidden());
	}

	// ---------------------------------------------------------------------------
	// Doğru rol — yetki katmanını geçebilmeli
	// ---------------------------------------------------------------------------

	@Test
	void clientEndpoint_withClientRole_passesAuthorizationLayer() throws Exception {
		mockMvc.perform(get("/api/v1/finance/transactions").header("Authorization", clientToken()))
			.andExpect(status().isOk());
	}

	@Test
	void coachEndpoint_withCoachRole_passesAuthorizationLayer() throws Exception {
		mockMvc.perform(get("/api/v1/finance/coach/packages").header("Authorization", coachToken()))
			.andExpect(status().isOk());
	}

}
