package com.gym.v2.nutrition.dto;

import com.gym.v2.nutrition.entity.MealType;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;

/**
 * Öğün Kayıt İsteği (LogMealRequest) Bulgu #1 (Instant Geçişi) kapsamında güncellendi.
 */
public record LogMealRequest(@NotNull(message = "{validation.mealtype.notnull}") MealType mealType,

		Instant takenDatetime,

		List<@Valid LogMealItemRequest> items) {
}
