package com.gym.v2.security;

import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@code SecurityFilter} gövde (body) taraması.
 * <p>
 * Gövde yalnızca bir kez okunabildiği için filtre isteği sarmalar: hem tarar hem de
 * controller'ın gövdeyi okuyabilmesini sağlar. İki davranış birlikte test edilir —
 * yalnızca "zararlı istek engellendi" testi yazılsaydı, sarmalanan isteğin zincire
 * devredilmesi bozulduğunda tüm POST uçları boş gövde görmeye başlar ve bunu hiçbir test
 * yakalamazdı.
 * </p>
 */
@TestPropertySource(properties = "app.security.waf.enabled=true")
class WafBodyScanIT extends IntegrationTestBase {

	private String registerBody(String email, String firstName) {
		return registerBody(email, firstName, "Test bio");
	}

	private String registerBody(String email, String firstName, String bio) {
		return """
				{
				  "email": "%s",
				  "password": "Password123!",
				  "role": "CLIENT",
				  "phoneNumber": "+905555555555",
				  "firstName": "%s",
				  "lastName": "Yilmaz",
				  "bio": "%s",
				  "province": "Istanbul",
				  "district": "Kadikoy",
				  "experienceLevel": "INTERMEDIATE",
				  "dateOfBirth": "2000-01-01",
				  "gender": "MALE",
				  "heightCm": 180,
				  "weightKg": 80.00,
				  "goal": "KILO_VER",
				  "activityLevel": "MODERATELY_ACTIVE",
				  "profilePhotoUrl": "https://example.com/photo.jpg",
				  "specialization": "FITNESS",
				  "instagramUrl": "https://www.instagram.com/testcoach",
				  "websiteUrl": "https://example.com"
				}
				""".formatted(email, firstName, bio);
	}

	@Test
	void postWithHtmlInBody_isBlocked() throws Exception {
		mockMvc
			.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
				.content(registerBody("waf_xss@test.com", "<script>alert(1)</script>")))
			.andExpect(status().isForbidden());
	}

	/**
	 * Etiket, düz metnin ortasına gizlendiğinde de yakalanmalı. Yalnızca gövdenin tamamı
	 * bir {@code <script>} etiketinden ibaretken engelleyen bir filtre gerçek saldırıyı
	 * durdurmaz.
	 */
	@Test
	void htmlTagHiddenInsideNormalSentence_isBlocked() throws Exception {
		mockMvc
			.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
				.content(registerBody("waf_gizli@test.com", "Ahmet", "Merhaba <img src=x onerror=alert(1)> gorusuruz")))
			.andExpect(status().isForbidden());
	}

	/**
	 * WAF'ın maliyeti yalnızca "saldırıyı kaçırmak" değil, **normal kullanıcıyı
	 * engellemektir**. Aşağıdaki iki metin günlük Türkçe yazışmada sıradan; hiçbiri HTML
	 * etiketi içermiyor. Bunlar 403 alıyorsa sohbet, besin adı ve biyografi gibi her
	 * serbest metin alanı kullanıcının yüzüne kapanıyor demektir.
	 */
	@Test
	void plainTextWithAmpersand_isNotBlocked() throws Exception {
		mockMvc
			.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
				.content(registerBody("waf_ve@test.com", "Ahmet", "Protein & kreatin kullaniyorum")))
			.andExpect(status().isCreated());
	}

	@Test
	void plainTextWithLessThanSign_isNotBlocked() throws Exception {
		mockMvc
			.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
				.content(registerBody("waf_kucuktur@test.com", "Ahmet", "Hedefim < 80 kg")))
			.andExpect(status().isCreated());
	}

	@Test
	void postWithCleanBody_reachesTheControllerWithItsBodyIntact() throws Exception {
		// Kayıt başarılı olmalı: gövde sarmalandıktan sonra da okunabilir olduğu için
		// controller alanları görebiliyor. Gövde kaybolsaydı doğrulama hatası (400)
		// dönerdi.
		mockMvc
			.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
				.content(registerBody("waf_temiz@test.com", "Ahmet")))
			.andExpect(status().isCreated());
	}

}
