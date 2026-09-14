package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.nutrition.dto.LogMealRequest;
import com.gym.v2.nutrition.dto.MealEntryResponse;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.service.MealLogService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

import java.util.Optional;

/**
 * Kullanıcıların günlük (Bugün ne yedim?) öğün girdilerini yönetir.
 */
@RestController
@RequestMapping("/api/v1/nutrition/meal-logs")
public class MealLogController {

	private final MealLogService mealLogService;

	private final Clock clock;

	public MealLogController(MealLogService mealLogService, Clock clock) {
		this.mealLogService = mealLogService;
		this.clock = clock;
	}

	@GetMapping("/daily")
	public ApiResponse<List<MealEntryResponse>> getDailyLogs(
			@RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
		LocalDate targetDate = (date != null) ? date : LocalDate.now(clock);
		return ApiResponse.success(mealLogService.getDailyMealEntries(targetDate), "Günlük öğün kayıtları getirildi.",
				clock.instant());
	}

	@GetMapping("/today")
	public ApiResponse<List<MealEntryResponse>> getTodayLogs() {
		return ApiResponse.success(mealLogService.getDailyMealEntries(LocalDate.now(clock)),
				"Bugünkü öğün kayıtları getirildi.", clock.instant());
	}

	@PostMapping("/log")
	public ApiResponse<MealEntryResponse> logMeal(@RequestBody LogMealRequest request) {
		return ApiResponse.success(mealLogService.logMealEntry(request), "Öğün başarıyla kaydedildi.", clock.instant());
	}

	@PostMapping("/{mealType}/add-food")
	public ApiResponse<MealEntryResponse> addFoodToLog(@PathVariable MealType mealType, @RequestParam Long foodId,
			@RequestParam BigDecimal amount,
			@RequestParam(required = false, defaultValue = "false") boolean ignoreOverride) {
		return ApiResponse.success(mealLogService.addFoodToMealLog(mealType, foodId, amount, ignoreOverride),
				"Besin öğüne başarıyla eklendi.", clock.instant());
	}

	@DeleteMapping("/{entryId}")
	public ApiResponse<Void> deleteMealEntry(@PathVariable Long entryId) {
		mealLogService.deleteMealEntry(entryId);
		return ApiResponse.success(null, "Öğün kaydı başarıyla silindi.", clock.instant());
	}

	@DeleteMapping("/items/{itemId}")
	public ApiResponse<MealEntryResponse> deleteMealItem(@PathVariable Long itemId) {
		Optional<MealEntryResponse> response = mealLogService.deleteMealItem(itemId);

		return response
			.map(mealEntryResponse -> ApiResponse.success(mealEntryResponse, "Besin öğünden başarıyla silindi.",
					clock.instant()))
			.orElseGet(() -> ApiResponse.success(null, "Besin öğünden silindi.", clock.instant()));
	}

}
