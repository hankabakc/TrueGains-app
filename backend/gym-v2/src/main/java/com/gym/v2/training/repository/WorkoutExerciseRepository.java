package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WorkoutExercise;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Collection;
import java.util.List;

public interface WorkoutExerciseRepository extends JpaRepository<WorkoutExercise, Long> {

	java.util.Optional<WorkoutExercise> findByIdAndWorkoutDay_TrainingBlock_Client_Id(Long id, Long clientId);

	List<WorkoutExercise> findAllByIdInAndWorkoutDay_TrainingBlock_Client_Id(Collection<Long> ids, Long clientId);

	/**
	 * İnternetsiz oluşturulan programın egzersizleri, cihazın verdiği geçici kimlikle
	 * (G-74). Arama egzersizin programının sahibi sporcuyla sınırlı; gün birlikte gelir,
	 * oturum programını ve gününü bu egzersizden alır.
	 */
	@Query("SELECT we FROM WorkoutExercise we JOIN FETCH we.workoutDay d "
			+ "WHERE we.localId IN :localIds AND d.trainingBlock.client.id = :clientId")
	List<WorkoutExercise> findAllByLocalIdsOfClient(@Param("localIds") Collection<String> localIds,
			@Param("clientId") Long clientId);

}
