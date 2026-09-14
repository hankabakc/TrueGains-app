package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import java.math.BigDecimal;
import java.util.List;

public record MealTemplateDetailResponse(Long id, String name, List<MealType> applicableMealTypes,
		List<MealIngredientResponse> ingredients, BigDecimal totalCalories, BigDecimal totalProtein,
		BigDecimal totalCarbs, BigDecimal totalFat,
		// Mikrolar
		BigDecimal totalSugar, BigDecimal totalFiber, BigDecimal totalSodium, BigDecimal totalPotassium,
		BigDecimal totalCholesterol) {
}
