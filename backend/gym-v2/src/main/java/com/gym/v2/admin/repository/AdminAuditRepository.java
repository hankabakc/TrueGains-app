package com.gym.v2.admin.repository;

import com.gym.v2.core.entity.AuditLog;
import java.time.Instant;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Denetim defteri okumasi.
 * <p>
 * Salt okunur ve OYLE KALMALI: denetim kaydinin degistirilebilir ya da silinebilir
 * olmasi, kaydin kendisini degersiz kilar. Panel defteri yalnizca okur.
 * </p>
 */
public interface AdminAuditRepository extends Repository<AuditLog, Long> {

	/**
	 * {@code emailPattern} HAZIR gelir: kucuk harfe cevrilmis ve % ile sarilmis.
	 * <p>
	 * Sorguda {@code LOWER(:email)} yazilamaz: parametre null oldugunda PostgreSQL tipini
	 * cikaramayip {@code bytea} sayiyor ve "function lower(bytea) does not exist" ile
	 * patliyor. Fonksiyonu parametreye degil yalnizca SUTUNA uygulayinca sorun ortadan
	 * kalkiyor. {@code since}/{@code until} hiçbir zaman null gelmez; bkz.
	 * AdminAuditService.
	 * </p>
	 */
	@Query("""
			SELECT a FROM AuditLog a
			WHERE (:action IS NULL OR a.action = :action)
			  AND (:emailPattern IS NULL OR LOWER(a.userEmail) LIKE :emailPattern)
			  AND a.createdAt >= :since
			  AND a.createdAt < :until
			ORDER BY a.createdAt DESC, a.id DESC
			""")
	Page<AuditLog> search(@Param("action") String action, @Param("emailPattern") String emailPattern,
			@Param("since") Instant since, @Param("until") Instant until, Pageable pageable);

	@Query("SELECT DISTINCT a.action FROM AuditLog a ORDER BY a.action")
	List<String> distinctActions();

}
