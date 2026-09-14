package com.gym.v2.auth.scheduler;

import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import java.time.Clock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Süresi dolmuş oturum anahtarlarını temizler.
 * <p>
 * Her giriş bir {@code refresh_token}, her çıkış bir {@code blacklisted_token} satırı
 * üretiyor ve <b>hiçbiri silinmiyordu</b>. Silme sorguları
 * ({@code deleteAllExpiredSince}) iki depoda da yazılmıştı ama çağıran yoktu. Aylar
 * içinde bu iki tablo veritabanının en büyükleri hâline gelir; giriş her seferinde
 * {@code blacklisted_token} tablosuna baktığı için de yavaşlama doğrudan kimlik
 * doğrulamaya yansır.
 * </p>
 * <p>
 * Süresi geçmiş kaydın hiçbir işlevi yoktur: geçerlilik zaten token'ın kendi son kullanma
 * tarihinden anlaşılır, kara listede tutulmasına gerek kalmaz.
 * </p>
 */
@Component
public class ExpiredTokenCleanupScheduler {

	private static final Logger log = LoggerFactory.getLogger(ExpiredTokenCleanupScheduler.class);

	private final RefreshTokenRepository refreshTokenRepository;

	private final BlacklistedTokenRepository blacklistedTokenRepository;

	private final Clock clock;

	public ExpiredTokenCleanupScheduler(RefreshTokenRepository refreshTokenRepository,
			BlacklistedTokenRepository blacklistedTokenRepository, Clock clock) {
		this.refreshTokenRepository = refreshTokenRepository;
		this.blacklistedTokenRepository = blacklistedTokenRepository;
		this.clock = clock;
	}

	/** Abonelik görevinden (03:00) sonra, çakışmasın diye 03:30'da çalışır. */
	@Scheduled(cron = "0 30 3 * * *", zone = "${app.timezone:Europe/Istanbul}")
	@Transactional
	public void purgeExpiredTokens() {
		cleanUpExpiredTokens();
	}

	/**
	 * Temizliği yapar. Zamanlayıcıdan ayrı bir metot olarak durur ki test doğrudan
	 * çağırabilsin — cron beklemeden davranış doğrulanabilir.
	 */
	@Transactional
	public void cleanUpExpiredTokens() {
		refreshTokenRepository.deleteAllExpiredSince(clock.instant());
		blacklistedTokenRepository.deleteAllExpiredSince(clock.instant());
		log.info("[BAKIM] Süresi dolmuş oturum anahtarları temizlendi.");
	}

}
