package com.gym.v2.training.repository;

import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

	List<Exercise> findByMuscleGroup(MuscleGroup muscleGroup);

}
