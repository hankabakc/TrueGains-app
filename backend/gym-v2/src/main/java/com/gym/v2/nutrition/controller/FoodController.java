package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import com.gym.v2.nutrition.dto.FoodCreateRequest;
import com.gym.v2.nutrition.dto.FoodOverrideRequest;
import com.gym.v2.nutrition.dto.FoodResponse;
import com.gym.v2.nutrition.dto.MealHistoryResponse;
import com.gym.v2.nutrition.service.FoodService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/nutrition/foods")
public class FoodController {

	private final FoodService foodService;

	private final Clock clock;

	public FoodController(FoodService foodService, Clock clock) {
		this.foodService = foodService;
		this.clock = clock;
	}

	@PostMapping
	public ApiResponse<FoodResponse> createCustomFood(@Valid @RequestBody FoodCreateRequest request) {
		FoodResponse response = foodService.createCustomFood(request);
		return ApiResponse.success(response, "Özel besin başarıyla eklendi.", clock.instant());
	}

	/**
	 * GET /api/v1/nutrition/foods/search?query=... Besin arama yapar.
	 */
	@GetMapping("/search")
	public ApiResponse<List<FoodResponse>> searchFood(@RequestParam String query) {
		List<FoodResponse> response = foodService.searchFood(query);
		return ApiResponse.success(response, "Besin arama sonuçları listelendi.", clock.instant());
	}

	@GetMapping("/recent-grouped")
	public ApiResponse<List<MealHistoryResponse>> getRecentGroupedFoods() {
		List<MealHistoryResponse> response = foodService.getRecentGroupedFoods();
		return ApiResponse.success(response, "Geçmiş besinler öğünlere göre listelendi.", clock.instant());
	}

	/**
	 * GET /api/v1/nutrition/foods/recent Son yenen besinleri getirir.
	 */
	@GetMapping("/recent")
	public ApiResponse<List<FoodResponse>> getRecentFoods() {
		List<FoodResponse> response = foodService.getRecentFoods();
		return ApiResponse.success(response, "Son yenen besinler listelendi.", clock.instant());
	}

	/**
	 * GET /api/v1/nutrition/foods/overridden Kullanıcının kendisi için özelleştirdiği
	 * (ezdiği) besinleri getirir.
	 */
	@GetMapping("/overridden")
	public ApiResponse<List<FoodResponse>> getOverriddenFoods() {
		List<FoodResponse> response = foodService.getOverriddenFoods();
		return ApiResponse.success(response, "Size özel besinler listelendi.", clock.instant());
	}

	@GetMapping("/mine")
	public ApiResponse<List<FoodResponse>> getMyCustomFoods() {
		List<FoodResponse> response = foodService.getMyCustomFoods();
		return ApiResponse.success(response, "Manuel eklediğiniz besinler listelendi.", clock.instant());
	}

	/**
	 * GET /api/v1/nutrition/foods/{id} Besin detayını getirir.
	 */
	@GetMapping("/{id}")
	public ApiResponse<FoodResponse> getFoodDetails(@PathVariable Long id,
			@RequestParam(required = false, defaultValue = "false") boolean ignoreOverride) {
		FoodResponse response = foodService.getFoodDetails(id, ignoreOverride);
		return ApiResponse.success(response, "Besin detayları getirildi.", clock.instant());
	}

	@PostMapping("/{id}/override")
	public ApiResponse<FoodResponse> overrideFood(@PathVariable Long id,
			@Valid @RequestBody FoodOverrideRequest request) {
		FoodResponse response = foodService.overrideFood(id, request);
		return ApiResponse.success(response, "Besin değerleri size özel olarak güncellendi.", clock.instant());
	}

	/**
	 * GET /api/v1/nutrition/foods/barcode/{barcode} Barkoda göre besin getirir (Yerel +
	 * OFF Hibrit).
	 */
	@GetMapping("/barcode/{barcode}")
	public ApiResponse<FoodResponse> getFoodByBarcode(@PathVariable String barcode) {
		FoodResponse response = foodService.getFoodByBarcode(barcode);
		return ApiResponse.success(response, "Barkod ile besin verisi başarıyla getirildi.", clock.instant());
	}

	/**
	 * POST /api/v1/nutrition/foods/barcode/{barcode}/override Barkoda göre besin
	 * değerlerini kullanıcıya özel olarak ezer.
	 */
	@PostMapping("/barcode/{barcode}/override")
	public ApiResponse<FoodResponse> overrideFoodByBarcode(@PathVariable String barcode,
			@Valid @RequestBody FoodOverrideRequest request) {
		FoodResponse response = foodService.overrideFoodByBarcode(barcode, request);
		return ApiResponse.success(response, "Besin değerleri barkod üzerinden size özel olarak güncellendi.",
				clock.instant());
	}

	@DeleteMapping("/{id}/override")
	public ApiResponse<Void> deleteOverride(@PathVariable Long id) {
		foodService.deleteOverride(id);
		return ApiResponse.success(null, "Besin değerleri orijinal haline geri döndürüldü.", clock.instant());
	}

}
