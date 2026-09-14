package com.gym.v2.security;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.BlacklistedToken;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.support.IntegrationTestBase;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Access token yaşam döngüsü testleri.
 * <p>
 * <b>Neden kritik:</b> istemcideki {@code auth_interceptor.dart} token yenilemeyi
 * <b>yalnızca 401</b> yanıtında tetikler. Süresi dolmuş token 401 dışında bir kod
 * döndürürse yenileme hiç çalışmaz ve kullanıcı sessizce oturumdan düşer. Bu davranış
 * daha önce hiçbir testle kapsanmıyordu (denetim notu U1).
 * </p>
 * <p>
 * Token'lar üretim sınıfı çağrılmadan, aynı algoritma testte bağımsız uygulanarak
 * üretilir; aksi hâlde imzalama bozulsa bile test yeşil kalırdı.
 * </p>
 */
class TokenLifecycleIT extends IntegrationTestBase {

	/** {@code application-test.properties} içindeki JWT anahtarı (yalnızca test). */
	private static final String SECRET = "dGVzdC1vbmx5LWp3dC1zaWduaW5nLWtleS1ub3QtZm9yLXByb2R1Y3Rpb24tdXNl";

	private static final String PROTECTED_ENDPOINT = "/api/v1/coaches/measurements/shared";

	@Autowired
	private BlacklistedTokenRepository blacklistedTokenRepository;

	private static SecretKey signingKey() {
		return Keys.hmacShaKeyFor(Decoders.BASE64.decode(SECRET));
	}

	/**
	 * Verilen geçerlilik penceresiyle token üretir. Geçmiş tarihli pencere vererek süresi
	 * dolmuş token elde edilir.
	 */
	private static String tokenFor(AppUser user, String jti, Instant issuedAt, Instant expiresAt) {
		Map<String, Object> claims = new HashMap<>();
		claims.put("userId", user.getId());
		claims.put("role", user.getRole().name());
		claims.put(Claims.ID, jti);
		return Jwts.builder()
			.claims(claims)
			.subject(user.getEmail())
			.issuedAt(Date.from(issuedAt))
			.expiration(Date.from(expiresAt))
			.signWith(signingKey(), Jwts.SIG.HS256)
			.compact();
	}

	@Test
	void expiredAccessToken_returnsUnauthorizedSoClientCanRefresh() throws Exception {
		AppUser coach = createUser("expired@test.com", UserRole.COACH);
		Instant now = Instant.now();
		String expired = tokenFor(coach, UUID.randomUUID().toString(), now.minus(2, ChronoUnit.HOURS),
				now.minus(1, ChronoUnit.HOURS));

		mockMvc.perform(get(PROTECTED_ENDPOINT).header("Authorization", "Bearer " + expired))
			.andExpect(status().isUnauthorized())
			.andExpect(jsonPath("$.success").value(false));
	}

	@Test
	void blacklistedAccessToken_returnsUnauthorized() throws Exception {
		AppUser coach = createUser("blacklisted@test.com", UserRole.COACH);
		String jti = UUID.randomUUID().toString();
		Instant now = Instant.now();
		String token = tokenFor(coach, jti, now, now.plus(1, ChronoUnit.HOURS));

		// Çıkış yapılmış oturumu taklit et: jti kara listede.
		blacklistedTokenRepository.saveAndFlush(new BlacklistedToken(jti, now.plus(24, ChronoUnit.HOURS)));

		mockMvc.perform(get(PROTECTED_ENDPOINT).header("Authorization", "Bearer " + token))
			.andExpect(status().isUnauthorized())
			.andExpect(jsonPath("$.success").value(false));
	}

	@Test
	void tokenSignedWithWrongSecret_returnsUnauthorized() throws Exception {
		AppUser coach = createUser("forged@test.com", UserRole.COACH);
		Instant now = Instant.now();
		SecretKey foreignKey = Keys
			.hmacShaKeyFor(Decoders.BASE64.decode("9999999999999999999999999999999999999999999999999999999999999999"));
		String forged = Jwts.builder()
			.subject(coach.getEmail())
			.claim(Claims.ID, UUID.randomUUID().toString())
			.issuedAt(Date.from(now))
			.expiration(Date.from(now.plus(1, ChronoUnit.HOURS)))
			.signWith(foreignKey, Jwts.SIG.HS256)
			.compact();

		mockMvc.perform(get(PROTECTED_ENDPOINT).header("Authorization", "Bearer " + forged))
			.andExpect(status().isUnauthorized());
	}

	@Test
	void freshlyIssuedToken_isAcceptedByProtectedEndpoint() throws Exception {
		AppUser coach = createUser("fresh@test.com", UserRole.COACH);
		Instant now = Instant.now();
		String valid = tokenFor(coach, UUID.randomUUID().toString(), now, now.plus(1, ChronoUnit.HOURS));

		mockMvc.perform(get(PROTECTED_ENDPOINT).header("Authorization", "Bearer " + valid)).andExpect(status().isOk());
	}

}
