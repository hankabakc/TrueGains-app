package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Öğün tipi bazlı kalori dağılımı DTO'su. BigDecimal standardizasyonu uygulandı.
 */
public record MealTypeBreakdownResponse(String mealLabel, BigDecimal calories, BigDecimal percentage) {
}
