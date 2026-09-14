package com.gym.v2.training.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * GYMAPP-V2 Log Record DTO: Sporcunun gerçekleşen set verilerini taşır.
 */
public record WorkoutLogDTO(@JsonProperty("id") Long id, @JsonProperty("exercise_id") Long exerciseId,
		@JsonProperty("exercise_name") String exerciseName, @JsonProperty("set_index") Integer setIndex,
		@JsonProperty("actual_weight") BigDecimal actualWeight, @JsonProperty("actual_reps") Integer actualReps,
		@JsonProperty("rpe") Integer rpe, @JsonProperty("duration_seconds") Integer durationSeconds,
		@JsonProperty("created_at") Instant createdAt) {
}
