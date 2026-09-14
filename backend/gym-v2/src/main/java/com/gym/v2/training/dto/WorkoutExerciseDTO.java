package com.gym.v2.training.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gym.v2.training.entity.MuscleGroup;
import java.math.BigDecimal;
import java.util.List;

/**
 * GYMAPP-V2 Egzersiz Hedef Record DTO: Koçun belirlediği hedefleri ve sporcunun loglarını
 * taşır.
 */
public record WorkoutExerciseDTO(@JsonProperty("id") Long id, @JsonProperty("exercise_id") Long exerciseId,
		@JsonProperty("exercise_name") String exerciseName, @JsonProperty("muscle_group") MuscleGroup muscleGroup,
		@JsonProperty("target_sets") Integer targetSets, @JsonProperty("target_reps") String targetReps,
		@JsonProperty("target_weight") BigDecimal targetWeight,
		@JsonProperty("rest_time_seconds") Integer restTimeSeconds,
		@JsonProperty("superset_group_id") String supersetGroupId, @JsonProperty("order_index") Integer orderIndex,
		@JsonProperty("coach_notes") String coachNotes, @JsonProperty("is_to_failure") Boolean isToFailure,
		@JsonProperty("logs") List<WorkoutLogDTO> logs) {
}
