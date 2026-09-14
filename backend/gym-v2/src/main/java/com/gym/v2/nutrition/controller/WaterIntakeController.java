package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.service.WaterIntakeService;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/nutrition/water")
public class WaterIntakeController {

	private final WaterIntakeService waterIntakeService;

	private final java.time.Clock clock;

	public WaterIntakeController(WaterIntakeService waterIntakeService, java.time.Clock clock) {
		this.waterIntakeService = waterIntakeService;
		this.clock = clock;
	}

	@PostMapping
	public ApiResponse<WaterIntakeResponse> addWater(@RequestParam Integer amountMl) {
		return ApiResponse.success(waterIntakeService.addWater(amountMl), "Su tüketimi başarıyla kaydedildi.",
				clock.instant());
	}

	@GetMapping("/summary")
	public ApiResponse<WaterDailySummaryResponse> getDailySummary(@RequestParam(required = false) LocalDate date) {
		LocalDate queryDate = (date != null) ? date : LocalDate.now(clock);
		return ApiResponse.success(waterIntakeService.getDailySummary(queryDate), "Günlük su özeti getirildi.",
				clock.instant());
	}

	@PostMapping("/target")
	public ApiResponse<Void> updateTarget(@RequestParam Integer targetMl) {
		waterIntakeService.updateTarget(targetMl);
		return ApiResponse.success(null, "Su hedefi güncellendi.", clock.instant());
	}

	@PostMapping("/glass")
	public ApiResponse<CustomGlassResponse> addCustomGlass(@RequestParam String name, @RequestParam Integer sizeMl) {
		return ApiResponse.success(waterIntakeService.addCustomGlass(name, sizeMl), "Özel bardak eklendi.",
				clock.instant());
	}

	@DeleteMapping("/glass/{id}")
	public ApiResponse<Void> deleteCustomGlass(@PathVariable Long id) {
		waterIntakeService.deleteCustomGlass(id);
		return ApiResponse.success(null, "Özel bardak silindi.", clock.instant());
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> deleteWaterIntake(@PathVariable Long id) {
		waterIntakeService.deleteWaterIntake(id);
		return ApiResponse.success(null, "Su kaydı silindi.", clock.instant());
	}

	@GetMapping("/range")
	public ApiResponse<List<WaterDailyTotalResponse>> getRangeSummary(@RequestParam LocalDate start,
			@RequestParam LocalDate end) {
		return ApiResponse.success(waterIntakeService.getRangeSummary(start, end),
				"Tarih aralığı bazlı su özeti getirildi.", clock.instant());
	}

}
