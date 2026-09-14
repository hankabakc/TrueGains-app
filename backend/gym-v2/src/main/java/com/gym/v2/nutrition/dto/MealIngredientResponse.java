package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Öğün İçeriği Cevap DTO'su (MealIngredientResponse) Tüm besin değerlerini (makro ve
 * mikro) içerir.
 */
public record MealIngredientResponse(Long id, Long foodId, String foodName, String brand, BigDecimal amount,
		BigDecimal defaultAmount, BigDecimal protein, BigDecimal carbs, BigDecimal fat, BigDecimal calories,
		boolean isBrandVerified, boolean ignoreOverride,
		// Mikrolar
		BigDecimal sugar, BigDecimal fiber, BigDecimal sodium, BigDecimal potassium, BigDecimal cholesterol,
		Long recipeId, boolean isOverridden, boolean isCustom) {
}
