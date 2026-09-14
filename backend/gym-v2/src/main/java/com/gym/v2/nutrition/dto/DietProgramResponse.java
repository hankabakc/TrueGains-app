package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Diyet Programı Cevap DTO'su (DietProgramResponse) Bulgu #1 (Instant Geçişi) kapsamında
 * güncellendi.
 */
public record DietProgramResponse(Long id, Long ownerId, String name, boolean isMain, boolean isTemplate, String source,
		CoachInfo coach, Instant createdAt, BigDecimal targetCalories, BigDecimal targetProtein, BigDecimal targetCarbs,
		BigDecimal targetFat, BigDecimal targetSugar, BigDecimal targetFiber, BigDecimal targetSodium,
		BigDecimal targetCholesterol, BigDecimal targetPotassium, List<DietDayResponse> dietDays, Integer version,
		boolean isOrphaned) {
	public record CoachInfo(Long id, String email, String fullName) {
	}
}
