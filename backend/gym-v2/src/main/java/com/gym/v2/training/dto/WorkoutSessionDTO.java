package com.gym.v2.training.dto;

import java.time.Instant;
import java.util.List;

/**
 * GYMAPP-V2 İdman Oturumu DTO: Bir idmanın özet verilerini ve loglarını taşır. "Pure
 * Java" politikası gereği record olarak tanımlanmıştır.
 */
public record WorkoutSessionDTO(Long id, String workoutDayName, Integer totalSeconds, List<WorkoutLogDTO> logs,
		Instant createdAt, Long trainingBlockId, Long workoutDayId) {
}
