package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.DietProgram;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DietProgramRepository extends JpaRepository<DietProgram, Long> {

	/**
	 * Kullanıcıya ait tüm diyet programlarını bulur.
	 */
	List<DietProgram> findByOwnerId(Long ownerId);

	/**
	 * Kullanıcının ana (aktif) diyet programını bulur.
	 */
	Optional<DietProgram> findByOwnerIdAndMainTrue(Long ownerId);

	long countByOwnerId(Long ownerId);

	List<DietProgram> findByOwnerIdAndTemplateTrueOrderByCreatedAtDesc(Long ownerId);

	boolean existsByOwnerIdAndOriginalTemplateId(Long ownerId, Long originalTemplateId);

	/**
	 * Belirli bir şablondan kopyalanarak atanan tüm aktif diyet programlarını bulur.
	 * @param originalTemplateId Kaynak şablonun kimliği
	 * @return Şablona bağlı atanan programların listesi
	 */
	List<DietProgram> findByOriginalTemplateId(Long originalTemplateId);

	/**
	 * Belirli bir antrenör tarafından atanan (şablon olmayan) tüm diyet programlarını
	 * bulur.
	 * @param coachId Antrenörün kimliği
	 * @return Antrenörün atadığı diyet programlarının listesi
	 */
	List<DietProgram> findByCoachIdAndTemplateFalse(Long coachId);

}
