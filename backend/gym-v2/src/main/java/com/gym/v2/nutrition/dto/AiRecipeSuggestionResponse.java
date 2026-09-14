package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;
import java.util.List;

public record AiRecipeSuggestionResponse(Long recipeId, String recipeName, String assistantMessage, BigDecimal calories,
		BigDecimal protein, BigDecimal carbs, BigDecimal fat, List<IngredientDto> ingredients) {
	public record IngredientDto(String foodName, BigDecimal amount, String unit) {
	}
}
