package com.gym.v2.training.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * GYMAPP-V2 Antrenman Günü Record DTO: Bir günün içindeki egzersiz hedeflerini taşır.
 */
public record WorkoutDayDTO(@JsonProperty("id") Long id, @JsonProperty("name") String name,
		@JsonProperty("day_order") Integer dayOrder, @JsonProperty("is_magnet_enabled") Boolean isMagnetEnabled,
		@JsonProperty("exercises") List<WorkoutExerciseDTO> exercises) {
}
