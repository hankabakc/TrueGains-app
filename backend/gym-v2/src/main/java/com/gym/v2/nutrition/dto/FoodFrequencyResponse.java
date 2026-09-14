package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

public record FoodFrequencyResponse(String foodName, Long count, BigDecimal totalCalories, BigDecimal totalProtein,
		BigDecimal totalCarbs, BigDecimal totalFat) {
}
