package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/**
 * Çoklu öğün kaydı için kullanılan malzeme DTO'su. {@code localId}: cihazın kaleme
 * verdiği kimlik (G-72).
 */
public record LogMealItemRequest(Long foodId, Long recipeId, BigDecimal amount, String note,
		@Size(max = 36, message = "Yerel kimlik en fazla 36 karakter olabilir.") String localId) {
}
