package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

/**
 * Tarif oluşturma/güncelleme isteği DTO'su.
 */
public record RecipeRequest(
		@NotBlank(message = "{validation.recipe.name.notBlank}") @Size(max = 100,
				message = "{validation.recipe.name.size}") String name,
		String description, String instructions, String category, String imageUrl,
		List<RecipeIngredientRequest> ingredients) {
}
