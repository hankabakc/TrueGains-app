package com.gym.v2.measurement.repository;

import com.gym.v2.measurement.entity.Measurement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * GYMAPP-V2 Ölçüm Repository'si. Kullanıcıya ait ölçüm kayıtlarını tarih sırasına göre
 * listeler.
 */
public interface MeasurementRepository extends JpaRepository<Measurement, Long> {

	/**
	 * Belirli bir kullanıcının tüm ölçümlerini en yeniden en eskiye sıralar. Bu sıralama,
	 * gelişim grafiklerinde doğru zaman çizelgesi için kritiktir. Sayfalama desteği
	 * eklenmiştir.
	 */
	Page<Measurement> findByUser_ExternalIdOrderByCreatedAtDesc(String externalId, Pageable pageable);

	/**
	 * Belirli bir tarih aralığında (genellikle aynı gün) kullanıcının ölçümünü bulur.
	 * Aynı gün içerisinde tekil kayıt (Upsert) mantığı için kullanılır.
	 */
	Optional<Measurement> findFirstByUser_ExternalIdAndCreatedAtBetween(String externalId, Instant start, Instant end);

	/**
	 * Antrenörün belirli bir sporcunun paylaştığı ölçümleri sayfalama ile listeler.
	 */
	Page<Measurement> findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(Long userId, Pageable pageable);

	/**
	 * Antrenörün belirli bir sporcunun paylaştığı TÜM ölçümlerini (sayfalama olmadan)
	 * listeler. Tekil sporcu 360° görünümü için kullanılır.
	 */
	List<Measurement> findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(Long userId);

	/**
	 * Antrenörün kendisine bağlı öğrencilerin paylaştığı ölçümleri görmesini sağlar.
	 */
	@Query("SELECT m FROM Measurement m JOIN ClientEntity c ON m.user.id = c.userId "
			+ "WHERE c.coachId = :coachId AND m.isSharedWithCoach = true ORDER BY m.createdAt DESC")
	List<Measurement> findSharedByCoachId(@Param("coachId") Long coachId);

	/**
	 * Sporcunun seçtiği ölçümleri topluca antrenörüyle paylaşmasını sağlar. Güvenlik için
	 * userId kontrolü yapılır.
	 */
	@Modifying
	@Query("UPDATE Measurement m SET m.isSharedWithCoach = true WHERE m.user.id = :userId AND m.id IN :measurementIds")
	int bulkShareWithCoach(@Param("userId") Long userId, @Param("measurementIds") List<Long> measurementIds);

}
