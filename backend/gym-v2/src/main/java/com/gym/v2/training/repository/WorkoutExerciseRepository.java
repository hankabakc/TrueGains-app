package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WorkoutExercise;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Collection;
import java.util.List;

public interface WorkoutExerciseRepository extends JpaRepository<WorkoutExercise, Long> {

	java.util.Optional<WorkoutExercise> findByIdAndWorkoutDay_TrainingBlock_Client_Id(Long id, Long clientId);

	List<WorkoutExercise> findAllByIdInAndWorkoutDay_TrainingBlock_Client_Id(Collection<Long> ids, Long clientId);

}
