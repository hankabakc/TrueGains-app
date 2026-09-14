package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Yemek Tarifi İçerik Cevabı DTO (RecipeIngredientResponse)
 */
public record RecipeIngredientResponse(Long id, Long foodId, String foodName, String brand, BigDecimal amount,
		BigDecimal protein, BigDecimal carbs, BigDecimal fat, BigDecimal calories, String unit, Boolean isModified) {
}
