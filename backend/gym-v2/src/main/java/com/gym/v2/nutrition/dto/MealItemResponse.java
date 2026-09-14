package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

public record MealItemResponse(Long id, Long foodId, String foodName, String brand, FoodResponse food,
		RecipeResponse recipe, BigDecimal amount, String unitOverride, String note, BigDecimal calories,
		BigDecimal protein, BigDecimal carbs, BigDecimal fat, BigDecimal sugar, BigDecimal fiber, BigDecimal sodium,
		BigDecimal cholesterol, BigDecimal potassium) {
}
