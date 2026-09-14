package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Toplu besin ekleme isteği DTO'su.
 */
public record BulkIngredientRequest(Long foodId, Long recipeId,
		@NotNull(message = "{validation.nutrition.amount.notNull}") @DecimalMin(value = "0.01",
				message = "{validation.nutrition.amount.min}") BigDecimal amount,
		String note, boolean ignoreOverride) {
}
