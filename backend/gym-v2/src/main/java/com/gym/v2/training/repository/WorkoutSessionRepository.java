package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {

	/**
	 * Kullanıcının idman geçmişini tarihe göre azalan sırada getirir.
	 * <p>
	 * Loglar ve logların egzersizleri tek sorguda çekilir. Bunlar
	 * {@code WorkoutSessionDTO} içine haritalandığı için tembel bırakılırlarsa oturum
	 * başına ayrı sorgu üretilir ve ekranın maliyeti kullanıcının idman sayısıyla
	 * birlikte büyür.
	 * </p>
	 */
	@Query("SELECT DISTINCT s FROM WorkoutSession s " + "LEFT JOIN FETCH s.logs l "
			+ "LEFT JOIN FETCH l.workoutExercise we " + "LEFT JOIN FETCH we.exercise "
			+ "LEFT JOIN FETCH l.performedExercise " + "WHERE s.user.id = :userId ORDER BY s.createdAt DESC")
	List<WorkoutSession> findHistoryWithLogs(@Param("userId") Long userId);

	// Belirli bir antrenman bloğu, kullanıcı ve tarih aralığına ait idman oturumlarını
	// getirir
	java.util.List<WorkoutSession> findByUserIdAndTrainingBlockIdAndCreatedAtBetween(Long userId, Long trainingBlockId,
			java.time.Instant start, java.time.Instant end);

}
