package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Öğün Girdisi Cevap DTO'su (MealEntryResponse) Bulgu #1 (Instant Geçişi) kapsamında
 * güncellendi.
 */
public record MealEntryResponse(Long id, Long clientId, Long plannedMealId, Instant takenDatetime, String photoUrl,
		String mealType, BigDecimal calories, BigDecimal protein, BigDecimal carbs, BigDecimal fat, BigDecimal sugar,
		BigDecimal fiber, BigDecimal sodium, BigDecimal cholesterol, BigDecimal potassium, String notes,
		List<MealItemResponse> items) {
}
