package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import java.util.List;

/**
 * Öğün Cevap DTO'su (MealResponse)
 */
public record MealResponse(Long id, MealType mealType, String name, int orderIndex,
		List<MealIngredientResponse> ingredients) {
}
