package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Yemek Tarifi İçerik İsteği DTO (RecipeIngredientRequest)
 */
public record RecipeIngredientRequest(Long foodId, BigDecimal amount) {
}
