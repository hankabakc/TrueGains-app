package com.gym.v2.nutrition.dto;

import java.util.List;

public record PlannedMealResponse(Long mealId, String mealType, List<MealIngredientResponse> plannedIngredients,
		boolean isConsumed, Long mealEntryId, List<Long> consumedIngredientIds) {
}
