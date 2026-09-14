package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.RefreshToken;
import com.gym.v2.auth.entity.AppUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {

	Optional<RefreshToken> findByToken(String token);

	/**
	 * Kullanıcıya ait tüm refresh token'ları veritabanı seviyesinde topluca siler. Select
	 * N + Delete N problemini önlemek için Bulk Delete kullanır.
	 */
	@Modifying
	@Query("DELETE FROM RefreshToken r WHERE r.user = :user")
	void deleteAllByUser(@Param("user") AppUser user);

	/**
	 * Süresi dolmuş tüm refresh token'ları veritabanı seviyesinde topluca siler.
	 */
	@Modifying
	@Query("DELETE FROM RefreshToken r WHERE r.expiryDate < :now")
	void deleteAllExpiredSince(@Param("now") Instant now);

	java.util.List<RefreshToken> findAllByUserOrderByExpiryDateAsc(AppUser user);

}
