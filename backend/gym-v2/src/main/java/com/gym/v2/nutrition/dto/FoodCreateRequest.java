package com.gym.v2.nutrition.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

/**
 * Özel Besin Oluşturma İstek DTO'su (FoodCreateRequest). Pure Java record ve Jakarta
 * Validation kurallarına uygundur.
 */
public record FoodCreateRequest(
		@NotBlank(message = "Besin adı zorunludur.") @Size(max = 150,
				message = "Besin adı en fazla 150 karakter olabilir.") String name,

		@Size(max = 100, message = "Marka en fazla 100 karakter olabilir.") String brand,

		@Size(max = 100, message = "Kategori en fazla 100 karakter olabilir.") String category,

		@NotBlank(message = "Birim zorunludur.") String defaultUnit,

		@NotNull(message = "Porsiyon miktarı zorunludur.") @DecimalMin(value = "0.01",
				message = "Porsiyon miktarı 0'dan büyük olmalıdır.") BigDecimal defaultAmount,

		@NotNull(message = "{validation.nutrition.targetCalories.min}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetCalories.min}") BigDecimal calories,

		@NotNull(message = "{validation.nutrition.targetProtein.min}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetProtein.min}") BigDecimal protein,

		@NotNull(message = "{validation.nutrition.targetCarbs.min}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetCarbs.min}") BigDecimal carbs,

		@NotNull(message = "{validation.nutrition.targetFat.min}") @DecimalMin(value = "0",
				message = "{validation.nutrition.targetFat.min}") BigDecimal fat,

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
