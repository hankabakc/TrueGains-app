package com.gym.v2.training.service;

import com.gym.v2.training.dto.ExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.repository.ExerciseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * Egzersiz kütüphanesini yöneten servis.
 */
@Service
public class ExerciseService {

	private final ExerciseRepository exerciseRepository;

	private final TrainingMapper trainingMapper;

	public ExerciseService(ExerciseRepository exerciseRepository, TrainingMapper trainingMapper) {
		this.exerciseRepository = exerciseRepository;
		this.trainingMapper = trainingMapper;
	}

	@Transactional(readOnly = true)
	public List<ExerciseDTO> getAllExercises() {
		List<Exercise> exercises = new ArrayList<>(exerciseRepository.findAll());
		exercises.sort((a, b) -> {
			int groupComparison = a.getMuscleGroup().compareTo(b.getMuscleGroup());
			if (groupComparison != 0) {
				return groupComparison;
			}
			return a.getName().compareToIgnoreCase(b.getName());
		});
		return trainingMapper.toExerciseDTOList(exercises);
	}

}
