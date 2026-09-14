package com.gym.v2.core;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.RefreshToken;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.auth.scheduler.ExpiredTokenCleanupScheduler;
import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * İşletim uçları: sağlık kontrolü ve bakım görevleri.
 */
class OperationsEndpointsIT extends IntegrationTestBase {

	@Autowired
	private ExpiredTokenCleanupScheduler cleanupScheduler;

	@Autowired
	private RefreshTokenRepository refreshTokenRepository;

	@PersistenceContext
	private EntityManager entityManager;

	/**
	 * İşletim uçlarının hiçbiri API portundan servis edilmemeli.
	 * <p>
	 * <b>DAVRANIŞ DEĞİŞİKLİĞİ (16.08.2026):</b> actuator önce API portunda yayınlanıyordu
	 * ve bu test sağlık ucunun oradan {@code 200} döndüğünü doğruluyordu. Metrik ucu
	 * eklenince (istek sayısı, gecikme, JVM bellek, bağlantı havuzu doluluğu) bu yapı
	 * savunulamaz hâle geldi: ya iç işletim bilgisi API portundan internete açılacaktı ya
	 * da Prometheus'a uygulama kimliği verilecekti.
	 * <p>
	 * Uçlar ayrı bir yönetim portuna alındı; o port compose ağında kalıyor, dışarı
	 * açılmıyor. Dolayısıyla API portundan bakıldığında actuator <b>hiç yok</b> — test
	 * artık bunu doğruluyor. Sağlık ucunun gerçekten çalıştığı compose healthcheck'i ile
	 * kanıtlanıyor (bkz. docker-compose.yml).
	 */
	@Test
	void actuatorIsNotServedOnTheApiPort() throws Exception {
		// Hangi 4xx döndüğü önemli değil (eşleşmeyen yol 404, yetkisiz yol 403); önemli
		// olan hiçbirinin içerik döndürmemesi. 200 dönen bir satır, iç işletim bilgisinin
		// API portuna sızdığı anlamına gelir.
		mockMvc.perform(get("/actuator/health")).andExpect(status().is4xxClientError());
		mockMvc.perform(get("/actuator/prometheus")).andExpect(status().is4xxClientError());
		mockMvc.perform(get("/actuator/env")).andExpect(status().is4xxClientError());
		mockMvc.perform(get("/actuator/beans")).andExpect(status().is4xxClientError());
	}

	/**
	 * Zorunlu sorgu parametresi eksikse <b>400</b> dönmeli.
	 * <p>
	 * Önceden 500 dönüyordu: {@code MissingServletRequestParameterException} genel
	 * {@code Exception} yakalayıcısına düşüyordu. Bu bir istemci hatası; 500 dönmesi hem
	 * istemciyi yanıltıyor hem de her eksik parametreyi Sentry'ye kritik hata olarak
	 * gönderip gerçek 500'leri gürültüye boğuyordu. Çalışan uygulamada iki uçta
	 * ({@code /diet/daily-log} ve {@code /social/discover}) doğrulandı.
	 * </p>
	 */
	@Test
	void missingRequiredQueryParameter_returns400NotServerError() throws Exception {
		mockMvc.perform(get("/api/v1/diet/daily-log").with(user("op@test.com").roles("CLIENT")))
			.andExpect(status().isBadRequest());
	}

	/** Yanlış tipte parametre de istemci hatasıdır, sunucu hatası değil. */
	@Test
	void wrongTypeQueryParameter_returns400NotServerError() throws Exception {
		mockMvc
			.perform(get("/api/v1/diet/daily-log").param("date", "tarih-degil")
				.with(user("op@test.com").roles("CLIENT")))
			.andExpect(status().isBadRequest());
	}

	/**
	 * Kimlikli bir isteğin tanımsız yola gitmesi <b>404</b> dönmeli.
	 * <p>
	 * Önceden 500 dönüyordu: {@code NoResourceFoundException} genel {@code Exception}
	 * yakalayıcısına düşüyordu. Adresi yanlış yazan istemci "sunucu çöktü" sanıyor,
	 * Sentry her yazım hatasını kritik hata sayıp gerçek 500'leri gürültüye boğuyordu.
	 * <p>
	 * Kimliksiz istekte 403 dönmesi doğru ve korunuyor — anonim kullanıcıya hangi
	 * adreslerin var olduğu sızdırılmaz.
	 */
	@Test
	void unknownPath_returns404ForAuthenticatedUser() throws Exception {
		mockMvc.perform(get("/api/v1/boyle-bir-uc-yok").with(user("op@test.com").roles("CLIENT")))
			.andExpect(status().isNotFound());
	}

	private RefreshToken tokenFor(AppUser user, String value, Instant expiry) {
		RefreshToken token = new RefreshToken();
		token.setUser(user);
		token.setToken(value);
		token.setExpiryDate(expiry);
		token.setDeviceId(SecurityConstants.DEFAULT_DEVICE_ID);
		return token;
	}

	/**
	 * Süresi dolmuş oturum anahtarları temizlenmeli. Silme sorguları yazılmıştı ama
	 * çağıran yoktu: her giriş bir satır bırakıyor, tablo sonsuza kadar büyüyordu.
	 */
	@Test
	void cleanup_removesExpiredRefreshTokensButKeepsValidOnes() {
		AppUser user = createUser("temizlik@test.com", UserRole.CLIENT);

		RefreshToken expired = tokenFor(user, "eski-token", Instant.now().minus(2, ChronoUnit.DAYS));
		RefreshToken valid = tokenFor(user, "gecerli-token", Instant.now().plus(7, ChronoUnit.DAYS));
		refreshTokenRepository.saveAllAndFlush(java.util.List.of(expired, valid));
		entityManager.clear();

		cleanupScheduler.cleanUpExpiredTokens();
		entityManager.flush();
		entityManager.clear();

		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(user))
			.as("süresi dolmuş anahtar silinmeli, geçerli olan durmalı — aksi hâlde temizlik oturumları koparır")
			.hasSize(1)
			.allSatisfy(token -> assertThat(token.getExpiryDate()).isAfter(Instant.now()));
	}

}
