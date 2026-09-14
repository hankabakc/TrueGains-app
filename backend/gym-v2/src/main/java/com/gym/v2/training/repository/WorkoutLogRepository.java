package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WorkoutLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface WorkoutLogRepository extends JpaRepository<WorkoutLog, Long> {

	List<WorkoutLog> findByWorkoutExerciseIdOrderBySetIndexAsc(Long workoutExerciseId);

	@Query("SELECT wl FROM WorkoutLog wl " + "LEFT JOIN wl.performedExercise pe "
			+ "WHERE wl.session.user.id = :userId "
			+ "AND COALESCE(pe.id, wl.workoutExercise.exercise.id) = :exerciseId " + "ORDER BY wl.createdAt ASC")
	List<WorkoutLog> findAllByUserIdAndExerciseIdOrderByCreatedAtAsc(Long userId, Long exerciseId);

}
