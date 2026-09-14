package com.gym.v2.training.dto;

import java.math.BigDecimal;

/**
 * GYMAPP-V2 İdman Oturumu Kayıt İsteği DTO: Toplu log gönderiminde her bir setin verisini
 * taşır.
 */
public record WorkoutLogRequestDTO(Long workoutExerciseId, Integer setIndex, BigDecimal actualWeight,
		Integer actualReps, Integer rpe, Integer durationSeconds, Long substituteExerciseId) {
}
