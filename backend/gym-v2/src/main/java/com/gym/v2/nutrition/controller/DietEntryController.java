package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import com.gym.v2.nutrition.dto.DailyDietLogResponse;
import com.gym.v2.nutrition.dto.MealEntryResponse;
import com.gym.v2.nutrition.service.DietEntryService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/diet")
public class DietEntryController {

	private final DietEntryService dietEntryService;

	private final Clock clock;

	public DietEntryController(DietEntryService dietEntryService, Clock clock) {
		this.dietEntryService = dietEntryService;
		this.clock = clock;
	}

	/**
	 * Günlük diyet özetini (Program + Loglar) getirir.
	 */
	@GetMapping("/daily-log")
	public ApiResponse<DailyDietLogResponse> getDailyLog(
			@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
		return ApiResponse.success(dietEntryService.getDailyLog(date), "Günlük diyet günlüğü başarıyla getirildi.",
				clock.instant());
	}

	/**
	 * Programdaki bir öğünü "yendi" (consumed=true) veya "yenilmedi" (consumed=false)
	 * olarak işaretler.
	 */
	@PostMapping("/log/toggle-planned")
	public ApiResponse<MealEntryResponse> togglePlannedMeal(
			@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date, @RequestParam Long mealId,
			@RequestParam boolean consumed,
			@RequestParam(value = "ingredientIds", required = false) List<Long> ingredientIds,
			@RequestParam(value = "ingredientIds[]", required = false) List<Long> ingredientIdsBracket) {
		List<Long> finalIds = (ingredientIds != null && !ingredientIds.isEmpty()) ? ingredientIds
				: ingredientIdsBracket;
		MealEntryResponse response = dietEntryService.togglePlannedMeal(date, mealId, consumed, finalIds);
		String message;
		if (consumed) {
			message = "Öğün yendi olarak işaretlendi.";
		}
		else {
			message = "Öğün işareti kaldırıldı.";
		}
		return ApiResponse.success(response, message, clock.instant());
	}

}
