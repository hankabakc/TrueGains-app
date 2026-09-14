package com.gym.v2.training.dto;

import com.gym.v2.training.entity.MuscleGroup;
import java.time.Instant;

/**
 * GYMAPP-V2 Egzersiz Record DTO: Kütüphanedeki egzersiz bilgilerini taşır.
 */
public record ExerciseDTO(Long id, String name, String description, MuscleGroup muscleGroup,
		@jakarta.validation.constraints.Pattern(regexp = "^https://.*",
				message = "Video URL HTTPS ile başlamalıdır ve güvenli bir kaynak olmalıdır.") String videoUrl,
		@jakarta.validation.constraints.Pattern(regexp = "^https://.*",
				message = "Görsel URL HTTPS ile başlamalıdır ve güvenli bir kaynak olmalıdır.") String imageUrl,
		String scientificName, String targetMuscleDetails, Instant createdAt) {
}
