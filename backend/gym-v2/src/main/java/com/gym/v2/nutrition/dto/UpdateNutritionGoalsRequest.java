package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * Beslenme hedeflerini güncelleme isteği DTO'su.
 */
public record UpdateNutritionGoalsRequest(
		@NotNull(message = "{validation.nutrition.targetCalories.notNull}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetCalories.min}") BigDecimal targetCalories,

		@NotNull(message = "{validation.nutrition.targetProtein.notNull}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetProtein.min}") BigDecimal targetProtein,

		@NotNull(message = "{validation.nutrition.targetCarbs.notNull}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetCarbs.min}") BigDecimal targetCarbs,

		@NotNull(message = "{validation.nutrition.targetFat.notNull}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetFat.min}") BigDecimal targetFat,

		@DecimalMin(value = "0", message = "{validation.nutrition.targetSugar.min}") BigDecimal targetSugar,

		@DecimalMin(value = "0", message = "{validation.nutrition.targetFiber.min}") BigDecimal targetFiber,

		@DecimalMin(value = "0", message = "{validation.nutrition.targetSodium.min}") BigDecimal targetSodium,

		@DecimalMin(value = "0", message = "{validation.nutrition.targetCholesterol.min}") BigDecimal targetCholesterol,

		@DecimalMin(value = "0", message = "{validation.nutrition.targetPotassium.min}") BigDecimal targetPotassium) {
}
