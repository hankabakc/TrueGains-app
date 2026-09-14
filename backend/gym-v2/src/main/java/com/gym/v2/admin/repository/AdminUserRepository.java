package com.gym.v2.admin.repository;

import com.gym.v2.admin.dto.AdminUserRowProjection;
import com.gym.v2.auth.entity.AppUser;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Yonetim panelinin kullanici sorgulari.
 * <p>
 * <b>KURALLAR §2.4 (IDOR) bilincli istisnasi:</b> uygulamanin geri kalani
 * {@code findByIdAndOwnerId} ile yalnizca sahibinin verisine bakar. Yonetim modulu tanimi
 * geregi sahiplik sinirini asar. Istisnanin gecerli olmasinin sarti: (1) yol
 * {@code /api/v1/admin/**} ADMIN rolune kilitli, (2) her cagri
 * {@code AdminAuditInterceptor} ile denetim defterine duser. Bu iki sart olmadan bu
 * arayuz kullanilamaz.
 * </p>
 * <p>
 * Arama E-POSTA uzerinden: {@code AppUser.email} duz metin ve indeksli. Isimler AES
 * sifreli oldugu icin SQL'de aranamiyor; isimle arama tum tabloyu bellege cekip cozmeyi
 * gerektirirdi ve olceklenmezdi. Isim listede GOSTERILIYOR (sayfa basina 20 kayit
 * coozuluyor), aranmiyor.
 * </p>
 */
public interface AdminUserRepository extends Repository<AppUser, Long> {

	@Query(value = """
			SELECT u.id AS id, u.email AS email, COALESCE(c.full_name, cl.full_name) AS fullName,
			       u.role AS role, u.is_active AS active, u.is_premium AS premium,
			       u.registered_at AS registeredAt, u.last_login_at AS lastLoginAt
			FROM app_user u
			LEFT JOIN coach c ON c.user_id = u.id
			LEFT JOIN client cl ON cl.user_id = u.id
			WHERE (CAST(:role AS text) IS NULL OR u.role = CAST(:role AS text))
			  AND (CAST(:query AS text) IS NULL
			       OR LOWER(u.email) LIKE LOWER('%' || CAST(:query AS text) || '%'))
			  AND (CAST(:activeOnly AS boolean) IS NULL OR u.is_active = CAST(:activeOnly AS boolean))
			ORDER BY u.registered_at DESC NULLS LAST, u.id DESC
			""", countQuery = """
			SELECT COUNT(*) FROM app_user u
			WHERE (CAST(:role AS text) IS NULL OR u.role = CAST(:role AS text))
			  AND (CAST(:query AS text) IS NULL
			       OR LOWER(u.email) LIKE LOWER('%' || CAST(:query AS text) || '%'))
			  AND (CAST(:activeOnly AS boolean) IS NULL OR u.is_active = CAST(:activeOnly AS boolean))
			""", nativeQuery = true)
	Page<AdminUserRowProjection> search(@Param("role") String role, @Param("query") String query,
			@Param("activeOnly") Boolean activeOnly, Pageable pageable);

}
