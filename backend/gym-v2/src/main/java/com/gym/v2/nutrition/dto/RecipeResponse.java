package com.gym.v2.nutrition.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.math.BigDecimal;

/**
 * Yemek Tarifi Cevabı DTO (RecipeResponse)
 */
public record RecipeResponse(Long id, String name, String description, String instructions, String category,
		String imageUrl, LocalDateTime createdAt, List<RecipeIngredientResponse> ingredients, BigDecimal totalCalories,
		BigDecimal totalProtein, BigDecimal totalCarbs, BigDecimal totalFat) {
}
