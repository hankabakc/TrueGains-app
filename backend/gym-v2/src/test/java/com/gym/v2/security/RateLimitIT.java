package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Hız sınırlama (rate limiting) entegrasyon testleri.
 * <p>
 * Denetimde üç bulgu çıkmıştı: kimlik doğrulama uçları normal trafikle aynı kovayı
 * paylaşıyordu (R1), {@code X-Forwarded-For} sorgusuz kabul edildiği için limit tamamen
 * atlatılabiliyordu (R2) ve 429 yanıtı {@code ApiResponse} zarfında değildi (R6). Bu
 * sınıf üçünün de kapandığını doğrular.
 * </p>
 * <p>
 * Limitler bu sınıfa özel olarak küçültülür; {@code application-test.properties} içindeki
 * cömert değerler diğer testlerin rastgele 429 almasını önlemek içindir.
 * </p>
 */
@TestPropertySource(properties = { "app.security.rate-limit.auth-capacity=3", "app.security.rate-limit.capacity=50",
		"app.security.rate-limit.upload-capacity=2" })
class RateLimitIT extends IntegrationTestBase {

	private static final String AUTH_ENDPOINT = "/api/v1/auth/login";

	private static final String UPLOAD_ENDPOINT = "/api/v1/files/upload";

	private static final String GENERAL_ENDPOINT = "/api/v1/coaches/measurements/shared";

	private static final String LOGIN_BODY = "{\"email\":\"x@test.com\",\"password\":\"Password123!\",\"deviceId\":\"d1\"}";

	/**
	 * Her test kendi IP'sini kullanır; kovalar IP başına tutulduğu için testler izole
	 * kalır.
	 */
	private MockHttpServletRequestBuilder fromIp(MockHttpServletRequestBuilder builder, String ip) {
		return builder.with(request -> {
			request.setRemoteAddr(ip);
			return request;
		});
	}

	private MockHttpServletRequestBuilder authRequest(String ip) {
		return fromIp(post(AUTH_ENDPOINT).contentType(MediaType.APPLICATION_JSON).content(LOGIN_BODY), ip);
	}

	@Test
	void authEndpoint_exceedingItsQuota_returnsTooManyRequests() throws Exception {
		String ip = "10.0.0.1";

		// Kota 3: ilk üç istek limit yüzünden engellenmemeli.
		for (int i = 0; i < 3; i++) {
			mockMvc.perform(authRequest(ip)).andExpect(status().is(not429()));
		}

		mockMvc.perform(authRequest(ip)).andExpect(status().isTooManyRequests());
	}

	@Test
	void rateLimitResponse_isWrappedInApiResponseEnvelope() throws Exception {
		String ip = "10.0.0.2";
		for (int i = 0; i < 3; i++) {
			mockMvc.perform(authRequest(ip));
		}

		// R6: istemci her yanıtı ApiResponse olarak ayrıştırıyor; düz metin mesajı
		// gösteremez.
		mockMvc.perform(authRequest(ip))
			.andExpect(status().isTooManyRequests())
			.andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
			.andExpect(jsonPath("$.success").value(false))
			.andExpect(jsonPath("$.message").isNotEmpty());
	}

	@Test
	void exhaustingAuthQuota_doesNotBlockGeneralEndpoints() throws Exception {
		String ip = "10.0.0.3";
		AppUser coach = createUser("ratelimit_coach@test.com", UserRole.COACH);

		// Auth kovasını tamamen tüket.
		for (int i = 0; i < 5; i++) {
			mockMvc.perform(authRequest(ip));
		}

		// R1: kovalar ayrı olduğu için normal uç hâlâ çalışmalı.
		mockMvc.perform(fromIp(get(GENERAL_ENDPOINT).header("Authorization", bearerTokenFor(coach)), ip))
			.andExpect(status().isOk());
	}

	@Test
	void forgedForwardedForHeader_doesNotResetTheQuota() throws Exception {
		String ip = "10.0.0.4";
		for (int i = 0; i < 3; i++) {
			mockMvc.perform(authRequest(ip));
		}

		// R2: saldırgan her istekte farklı bir X-Forwarded-For yazarak limiti
		// atlatamamalı.
		mockMvc.perform(authRequest(ip).header("X-Forwarded-For", "1.2.3.4")).andExpect(status().isTooManyRequests());
		mockMvc.perform(authRequest(ip).header("X-Forwarded-For", "5.6.7.8")).andExpect(status().isTooManyRequests());
	}

	@Test
	void quotaIsTrackedPerIpAddress() throws Exception {
		String exhausted = "10.0.0.5";
		for (int i = 0; i < 4; i++) {
			mockMvc.perform(authRequest(exhausted));
		}
		mockMvc.perform(authRequest(exhausted)).andExpect(status().isTooManyRequests());

		// Başka bir IP'nin kotası bundan etkilenmemeli.
		mockMvc.perform(authRequest("10.0.0.6")).andExpect(status().is(not429()));
	}

	/**
	 * Yükleme ucu kimlik doğrulaması istemez; kimliksiz çağrılabilen tek yazma ucu olduğu
	 * için kendi dar kovasını kullanır.
	 */
	@Test
	void uploadEndpoint_exceedingItsQuota_returnsTooManyRequests() throws Exception {
		String ip = "10.0.0.7";

		for (int i = 0; i < 2; i++) {
			mockMvc.perform(uploadRequest(ip)).andExpect(status().is(not429()));
		}

		mockMvc.perform(uploadRequest(ip)).andExpect(status().isTooManyRequests());
	}

	@Test
	void exhaustingUploadQuota_doesNotBlockGeneralEndpoints() throws Exception {
		String ip = "10.0.0.8";
		AppUser coach = createUser("upload_coach@test.com", UserRole.COACH);

		for (int i = 0; i < 4; i++) {
			mockMvc.perform(uploadRequest(ip));
		}

		// Kovalar ayrı: yükleme kotasını tüketmek normal gezinmeyi kilitlememeli.
		mockMvc.perform(fromIp(get(GENERAL_ENDPOINT).header("Authorization", bearerTokenFor(coach)), ip))
			.andExpect(status().isOk());
	}

	private org.springframework.test.web.servlet.RequestBuilder uploadRequest(String ip) {
		MockMultipartFile file = new MockMultipartFile("file", "foto.jpg", MediaType.IMAGE_JPEG_VALUE,
				new byte[] { (byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00 });
		return multipart(UPLOAD_ENDPOINT).file(file).with(request -> {
			request.setRemoteAddr(ip);
			return request;
		});
	}

	private static org.hamcrest.Matcher<Integer> not429() {
		return org.hamcrest.Matchers.not(429);
	}

	private static org.springframework.test.web.servlet.result.ContentResultMatchers content() {
		return org.springframework.test.web.servlet.result.MockMvcResultMatchers.content();
	}

}
