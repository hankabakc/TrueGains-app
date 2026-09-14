package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Çoklu öğün kaydı için kullanılan malzeme DTO'su.
 */
public record LogMealItemRequest(Long foodId, Long recipeId, BigDecimal amount, String note) {
}
