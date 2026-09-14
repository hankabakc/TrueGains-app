package com.gym.v2.nutrition.dto;

import java.util.List;

public record WaterDailySummaryResponse(Integer totalIntakeMl, Integer targetMl, List<WaterIntakeResponse> intakes,
		List<CustomGlassResponse> customGlasses) {
}
