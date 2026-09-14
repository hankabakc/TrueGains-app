package com.gym.v2.training.service;

import com.gym.v2.training.dto.ExerciseDTO;
import com.gym.v2.training.repository.ExerciseRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
		java.util.List<com.gym.v2.training.entity.Exercise> exercises = new java.util.ArrayList<>(
				exerciseRepository.findAll());
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
