package com.gym.v2.nutrition.dto;

import java.util.List;

/**
 * Günlük Diyet Özeti DTO O günün planlanan öğünlerini ve gerçekten yenen öğünlerini bir
 * arada tutar.
 */
public record DailyDietLogResponse(List<PlannedMealResponse> plannedMeals, List<MealEntryResponse> extraEntries) {
}
