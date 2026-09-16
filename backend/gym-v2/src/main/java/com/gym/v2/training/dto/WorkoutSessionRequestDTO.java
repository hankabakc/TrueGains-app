package com.gym.v2.training.dto;

import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * GYMAPP-V2 İdman Oturumu Kayıt İsteği: Bir idman bittiğinde tüm verileri tek seferde
 * göndermek için kullanılır. "Pure Java" politikası gereği record olarak tanımlanmıştır.
 */
public record WorkoutSessionRequestDTO(String workoutDayName, Integer totalSeconds, List<WorkoutLogRequestDTO> logs,
		Long trainingBlockId, Long workoutDayId,
		@Size(max = 36, message = "Yerel kimlik en fazla 36 karakter olabilir.") String localId) {
}
