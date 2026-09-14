package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.BlacklistedToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;

public interface BlacklistedTokenRepository extends JpaRepository<BlacklistedToken, Long> {

	boolean existsByJti(String jti);

	/**
	 * Süresi dolmuş token'ları veritabanı seviyesinde topluca siler. Select N + Delete N
	 * problemini önlemek için @Modifying ve Bulk Delete sorgusu kullanır.
	 * @param now Bu zamandan önceki tüm kayıtlar silinir.
	 */
	@Transactional
	@Modifying
	@Query("DELETE FROM BlacklistedToken b WHERE b.expiryDate < :now")
	void deleteAllExpiredSince(@Param("now") Instant now);

}
