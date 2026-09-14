package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

public record NutrientAnalysisResponse(String nutrientName, BigDecimal target, BigDecimal reached,
		BigDecimal difference, String unit) {
}
