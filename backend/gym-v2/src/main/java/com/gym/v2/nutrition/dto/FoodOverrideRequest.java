package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.DecimalMin;
import java.math.BigDecimal;

/**
 * Besin Değeri Ezme İstek DTO (FoodOverrideRequest). Nükleer Zırh (Validation) uygulandı.
 */
public record FoodOverrideRequest(
		@DecimalMin(value = "0", message = "{validation.nutrition.targetCalories.min}") BigDecimal calories,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetProtein.min}") BigDecimal protein,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetCarbs.min}") BigDecimal carbs,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFat.min}") BigDecimal fat,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetSugar.min}") BigDecimal sugar,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFiber.min}") BigDecimal fiber,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetSodium.min}") BigDecimal sodium,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetCholesterol.min}") BigDecimal cholesterol,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetPotassium.min}") BigDecimal potassium,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFat.min}") BigDecimal satFat,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFat.min}") BigDecimal transFat,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFat.min}") BigDecimal monoFat,
		@DecimalMin(value = "0", message = "{validation.nutrition.targetFat.min}") BigDecimal polyFat) {
}
