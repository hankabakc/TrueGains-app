package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.CoachEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;

public interface CoachRepository extends JpaRepository<CoachEntity, Long> {

	Optional<CoachEntity> findByUserId(Long userId);

	@org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
	@org.springframework.data.jpa.repository.Query("SELECT c FROM CoachEntity c WHERE c.userId = :userId")
	Optional<CoachEntity> findByUserIdWithLock(Long userId);

	Page<CoachEntity> findBySpecializationContainingIgnoreCase(String specialization, Pageable pageable);

	List<CoachEntity> findAllByUserIdIn(List<Long> userIds);

	// N+1 problemini çözmek amacıyla tek sorguda istatistikleri çeken gelişmiş keşif
	// sorgusu.
	//
	// profileScore: yorum yokken listeye anlamlı bir sıra vermek için. Deşifre
	// gerektirmeyen üç sinyal toplanır (deneyim yılı, aktif paket, sosyal bağlantı).
	// bio bilerek DIŞARIDA: şifreli olduğu için boş bio bile SQL'de dolu görünür,
	// ayırt etmek şifre uzunluğuna bakmayı gerektirirdi.
	//
	// ORDER BY neden Pageable'da değil de sorgunun içinde: Hibernate native sorguya
	// sıralama eklerken profileScore'u tablo sütunu sanıp "c." önekliyor ve
	// "column c.profilescore does not exist" ile patlıyor. Buraya yazılınca
	// alias'lar Postgres'in çıktı adları olarak çözülüyor. Pageable sıralamasız gelmeli;
	// gelirse Hibernate ikinci bir ORDER BY ekler ve sorgu sözdizimi bozulur.
	@org.springframework.data.jpa.repository.Query(
			value = "SELECT c.user_id AS userId, c.full_name AS fullName, c.bio AS bio, "
					+ "c.specialization AS specialization, c.currency AS currency, "
					+ "c.profile_photo_url AS profilePhotoUrl, c.instagram_url AS instagramUrl, "
					+ "c.province AS province, c.district AS district, " + "c.experience_years AS experienceYears, "
					+ "(SELECT MIN(sp.price) FROM subscription_package sp "
					+ "WHERE sp.coach_id = c.user_id AND sp.is_active = true) AS minPackagePrice, "
					+ "CAST((CASE WHEN c.experience_years IS NOT NULL THEN 1 ELSE 0 END) "
					+ "+ (CASE WHEN EXISTS (SELECT 1 FROM subscription_package sp2 "
					+ "WHERE sp2.coach_id = c.user_id AND sp2.is_active = true) THEN 1 ELSE 0 END) "
					+ "+ (CASE WHEN COALESCE(c.instagram_url, '') <> '' "
					+ "OR COALESCE(c.website_url, '') <> '' THEN 1 ELSE 0 END) AS integer) " + "AS profileScore, "
					+ "AVG(r.rating) AS averageRating, CAST(COUNT(r.id) AS integer) AS reviewCount, "
					+ "CAST((SELECT COUNT(*) FROM client cl WHERE cl.coach_id = c.user_id) AS integer) "
					+ "AS activeStudentCount " + "FROM coach c LEFT JOIN coach_review r ON r.coach_id = c.user_id "
					+ "WHERE (CAST(:specialization AS text) IS NULL "
					+ "OR LOWER(c.specialization) LIKE LOWER('%' || CAST(:specialization AS text) || '%')) "
					+ "GROUP BY c.user_id " + "HAVING (CAST(:minRating AS double precision) IS NULL "
					+ "OR AVG(r.rating) >= CAST(:minRating AS double precision)) "
					+ "ORDER BY CASE WHEN CAST(:sort AS text) = 'newest' THEN c.user_id END "
					+ "DESC NULLS LAST, averageRating DESC NULLS LAST, profileScore DESC, " + "c.user_id DESC",
			countQuery = "SELECT COUNT(*) FROM (" + "SELECT c.user_id "
					+ "FROM coach c LEFT JOIN coach_review r ON r.coach_id = c.user_id "
					+ "WHERE (CAST(:specialization AS text) IS NULL "
					+ "OR LOWER(c.specialization) LIKE LOWER('%' || CAST(:specialization AS text) || '%')) "
					+ "GROUP BY c.user_id " + "HAVING (CAST(:minRating AS double precision) IS NULL "
					+ "OR AVG(r.rating) >= CAST(:minRating AS double precision))" + ") sub",
			nativeQuery = true)
	Page<com.gym.v2.social.dto.CoachDiscoveryProjection> searchCoaches(@Param("specialization") String specialization,
			@Param("minRating") Double minRating, @Param("sort") String sort, Pageable pageable);

}
