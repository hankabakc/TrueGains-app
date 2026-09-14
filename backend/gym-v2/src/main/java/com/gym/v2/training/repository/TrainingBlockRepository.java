package com.gym.v2.training.repository;

import com.gym.v2.training.entity.TrainingBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TrainingBlockRepository extends JpaRepository<TrainingBlock, Long> {

	List<TrainingBlock> findByCoachIdAndIsTemplateTrue(Long coachId);

	List<TrainingBlock> findByCoachIdAndIsTemplateFalseAndIsActiveTrue(Long coachId);

	List<TrainingBlock> findByCoachIdAndIsTemplateFalse(Long coachId);

	@Query("SELECT b FROM TrainingBlock b WHERE b.templateId = :templateId AND b.isTemplate = false")
	List<TrainingBlock> findAssignedBlocksByTemplateId(@Param("templateId") Long templateId);

	/**
	 * Verilen kimliklerden veritabanında hâlâ var olanları tek sorguda döndürür.
	 * <p>
	 * "Bu programın şablonu silinmiş mi" kontrolü program başına {@code existsById} ile
	 * yapılırsa liste ekranının maliyeti program sayısıyla birlikte büyür.
	 * </p>
	 */
	@Query("SELECT b.id FROM TrainingBlock b WHERE b.id IN :ids")
	List<Long> findExistingIds(@Param("ids") java.util.Collection<Long> ids);

	@Query("SELECT b FROM TrainingBlock b LEFT JOIN FETCH b.coach " + "LEFT JOIN FETCH b.client "
			+ "LEFT JOIN FETCH b.workoutDays d " + "WHERE b.client.id = :clientId AND b.isActive = true")
	List<TrainingBlock> findByClientIdAndIsActiveTrueWithFetch(@Param("clientId") Long clientId);

	List<TrainingBlock> findByClientId(Long clientId);

	@Query("SELECT b FROM TrainingBlock b LEFT JOIN FETCH b.coach " + "LEFT JOIN FETCH b.client "
			+ "LEFT JOIN FETCH b.workoutDays d " + "WHERE b.client.id = :clientId AND b.isTemplate = false")
	List<TrainingBlock> findByClientIdWithFetch(@Param("clientId") Long clientId);

	List<TrainingBlock> findByClientIdAndIsActiveTrue(Long clientId);

	Optional<TrainingBlock> findByClientIdAndCoachIdAndName(Long clientId, Long coachId, String name);

	List<TrainingBlock> findByTemplateIdAndIsTemplateFalse(Long templateId);

}
