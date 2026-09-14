package com.gym.v2.core.security.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * IP bazlı Rate Limiting (Hız Sınırlama) yönetimi. Caffeine Cache kullanarak bellek
 * sızıntısını (Memory Leak) önler ve Bucket4j ile DDoS koruması sağlar.
 */
@Service
public class RateLimitingService {

	@Value("${app.security.rate-limit.capacity:20}")
	private int capacity;

	/**
	 * Kimlik doğrulama uçları için ayrı ve daha dar kova. Giriş / OTP / şifre sıfırlama
	 * uçları kaba kuvvet hedefidir; normal gezinme trafiğiyle aynı bütçeyi
	 * paylaşmamalıdır.
	 */
	@Value("${app.security.rate-limit.auth-capacity:10}")
	private int authCapacity;

	/**
	 * Dosya yükleme için ayrı ve dar kova. Yükleme ucu kayıt akışı gereği kimlik
	 * doğrulaması istemez; kimliksiz çağrılabilen tek yazma ucu olduğu için diski
	 * doldurma denemeleri normal gezinme bütçesinden bağımsız ve daha erken durdurulur.
	 */
	@Value("${app.security.rate-limit.upload-capacity:5}")
	private int uploadCapacity;

	@Value("${app.security.rate-limit.refill-minutes:1}")
	private int refillMinutes;

	// Bulgu #8: Bellek sızıntısını önlemek için Caffeine Cache kullanıldı.
	// 1 saat boyunca erişilmeyen IP kayıtları bellekten temizlenir.
	private final Cache<String, Bucket> cache = Caffeine.newBuilder()
		.expireAfterAccess(1, TimeUnit.HOURS)
		.maximumSize(100_000) // Maksimum 100 bin IP kaydı tutulur
		.build();

	/**
	 * Genel uçlar için IP başına kova oluşturur veya mevcut olanı döner.
	 */
	public Bucket resolveBucket(String ipAddress) {
		return cache.get("gen:" + ipAddress, key -> newBucket(capacity));
	}

	/**
	 * Kimlik doğrulama uçları için IP başına <b>ayrı</b> kova döner. Genel kovadan
	 * bağımsız olduğu için normal kullanım brute-force bütçesini tüketmez, brute-force da
	 * normal kullanımı kilitlemez.
	 */
	public Bucket resolveAuthBucket(String ipAddress) {
		return cache.get("auth:" + ipAddress, key -> newBucket(authCapacity));
	}

	/**
	 * Dosya yükleme ucu için IP başına <b>ayrı</b> kova döner.
	 */
	public Bucket resolveUploadBucket(String ipAddress) {
		return cache.get("upload:" + ipAddress, key -> newBucket(uploadCapacity));
	}

	private Bucket newBucket(int bucketCapacity) {
		// Bulgu #9: Limitler application.properties'ten okunur.
		Bandwidth limit = Bandwidth.builder()
			.capacity(bucketCapacity)
			.refillGreedy(bucketCapacity, Duration.ofMinutes(refillMinutes))
			.build();

		return Bucket.builder().addLimit(limit).build();
	}

}
