package com.gym.v2.nutrition.dto;

import java.util.List;

public record NutritionDashboardResponse(DailySummaryResponse dailySummary, WeeklySummaryResponse weeklySummary,
		List<FoodFrequencyResponse> frequentFoods, List<NutrientAnalysisResponse> nutrientAnalysis,
		boolean hasActiveProgram) {
}
