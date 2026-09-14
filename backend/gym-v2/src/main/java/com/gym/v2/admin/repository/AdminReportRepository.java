package com.gym.v2.admin.repository;

import com.gym.v2.social.entity.UserReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Moderasyon kuyrugu okumasi.
 * <p>
 * Sikayet edenin ve edilenin e-postasi tek sorguda geliyor; kuyruk sayfasinda 20 kayit
 * icin 40 ayri kullanici sorgusu (N+1) atmak kabul edilemez.
 * </p>
 */
public interface AdminReportRepository extends Repository<UserReport, Long> {

	@Query("""
			SELECT r, reporter.email, reported.email
			FROM UserReport r
			LEFT JOIN AppUser reporter ON reporter.id = r.reporterId
			LEFT JOIN AppUser reported ON reported.id = r.reportedUserId
			WHERE (:status IS NULL OR CAST(r.status AS string) = :status)
			  AND (:reportedUserId IS NULL OR r.reportedUserId = :reportedUserId)
			ORDER BY r.createdAt DESC, r.id DESC
			""")
	Page<Object[]> search(@Param("status") String status, @Param("reportedUserId") Long reportedUserId,
			Pageable pageable);

}
