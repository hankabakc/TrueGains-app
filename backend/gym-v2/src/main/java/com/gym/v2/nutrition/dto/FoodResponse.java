package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Besin Verisi DTO (FoodResponse) Record tipi kullanılarak immutability sağlanmıştır.
 */
public record FoodResponse(Long id, String name, String brand, String category, String defaultUnit,
		BigDecimal defaultAmount, BigDecimal calories, BigDecimal protein, BigDecimal carbs, BigDecimal fat,
		BigDecimal sugar, BigDecimal fiber, BigDecimal sodium, BigDecimal cholesterol, BigDecimal potassium,
		BigDecimal satFat, BigDecimal transFat, BigDecimal monoFat, BigDecimal polyFat, boolean isOverridden,
		boolean isBrandVerified, // Eklendi (Requirement)
		String barcode) {
}
