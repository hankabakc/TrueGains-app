package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;
import java.util.List;

public record WeeklySummaryResponse(List<DailySummaryResponse> dailyLogs, BigDecimal totalCalories,
		BigDecimal totalProtein, BigDecimal totalCarbs, BigDecimal totalFat, BigDecimal totalSugar,
		BigDecimal totalFiber, BigDecimal totalSodium, BigDecimal totalCholesterol, BigDecimal totalPotassium,
		BigDecimal targetCalories, BigDecimal targetProtein, BigDecimal targetCarbs, BigDecimal targetFat,
		BigDecimal targetSugar, BigDecimal targetFiber, BigDecimal targetSodium, BigDecimal targetCholesterol,
		BigDecimal targetPotassium) {
}
