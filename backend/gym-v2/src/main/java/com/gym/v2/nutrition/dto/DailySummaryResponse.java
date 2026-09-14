package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;
import java.util.List;

public record DailySummaryResponse(BigDecimal calories, BigDecimal protein, BigDecimal carbs, BigDecimal fat,
		BigDecimal sugar, BigDecimal fiber, BigDecimal sodium, BigDecimal cholesterol, BigDecimal potassium,
		List<MealTypeBreakdownResponse> mealBreakdown, List<FoodFrequencyResponse> dailyFoods) {
}
