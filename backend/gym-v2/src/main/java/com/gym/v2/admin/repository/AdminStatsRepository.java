package com.gym.v2.admin.repository;

import com.gym.v2.admin.dto.AdminOverviewProjection;
import com.gym.v2.auth.entity.AppUser;
import java.time.Instant;
import java.time.LocalDate;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Yönetim panelinin özet sayıları.
 * <p>
 * {@link Repository} tabanı bilerek seçildi: {@code JpaRepository} genişletilseydi bu
 * arayüz üzerinden {@code AppUser} kayıtlarına <b>yazma</b> da mümkün olurdu. Salt okunur
 * panelde yazma yüzeyi hiç açılmıyor.
 * </p>
 * <p>
 * Zaman eşikleri parametre olarak dışarıdan geliyor; sorgu içinde {@code NOW()}
 * kullanılmıyor ki {@code Clock} bean'i ile test edilebilsin (KURALLAR).
 * </p>
 */
public interface AdminStatsRepository extends Repository<AppUser, Long> {

	@Query(value = """
			SELECT
			  (SELECT COUNT(*) FROM app_user) AS totalUsers,
			  (SELECT COUNT(*) FROM app_user WHERE role = 'CLIENT') AS clientCount,
			  (SELECT COUNT(*) FROM app_user WHERE role = 'COACH') AS coachCount,
			  (SELECT COUNT(*) FROM app_user WHERE is_active = false) AS inactiveUsers,
			  (SELECT COUNT(*) FROM app_user WHERE registered_at >= :since24h) AS newLast24h,
			  (SELECT COUNT(*) FROM app_user WHERE registered_at >= :since7d) AS newLast7d,
			  (SELECT COUNT(*) FROM app_user WHERE registered_at >= :since30d) AS newLast30d,
			  (SELECT COUNT(*) FROM app_user WHERE last_login_at >= :since7d) AS activeLast7d,
			  (SELECT COUNT(*) FROM client WHERE coach_id IS NOT NULL) AS pairedClients,
			  (SELECT COUNT(*) FROM client_subscription
			     WHERE is_active = true AND end_date >= :today) AS activeSubscriptions
			""", nativeQuery = true)
	AdminOverviewProjection loadOverview(@Param("since24h") Instant since24h, @Param("since7d") Instant since7d,
			@Param("since30d") Instant since30d, @Param("today") LocalDate today);

}
