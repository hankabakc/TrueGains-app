package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.nutrition.dto.MealTemplateDetailResponse;
import com.gym.v2.nutrition.dto.MealTemplateResponse;
import com.gym.v2.nutrition.dto.TemplateUpdateRequest;
import com.gym.v2.nutrition.service.MealTemplateService;
import java.time.Clock;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/nutrition/templates")
public class MealTemplateController {

	private final MealTemplateService mealTemplateService;

	private final Clock clock;

	public MealTemplateController(MealTemplateService mealTemplateService, Clock clock) {
		this.mealTemplateService = mealTemplateService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<List<MealTemplateResponse>> getTemplates() {
		return ApiResponse.success(mealTemplateService.getTemplates(), "Şablonlar listelendi.", clock.instant());
	}

	@GetMapping("/{id}")
	public ApiResponse<MealTemplateDetailResponse> getTemplateDetail(@PathVariable Long id) {
		return ApiResponse.success(mealTemplateService.getTemplateDetail(id), "Şablon detayları getirildi.",
				clock.instant());
	}

	@PostMapping
	public ApiResponse<MealTemplateResponse> createTemplate(@RequestParam String name) {
		return ApiResponse.success(mealTemplateService.createTemplate(name), "Şablon oluşturuldu.", clock.instant());
	}

	@PutMapping("/{id}")
	public ApiResponse<Void> updateTemplate(@PathVariable Long id, @RequestBody TemplateUpdateRequest request) {
		mealTemplateService.updateTemplate(id, request);
		return ApiResponse.success(null, "Şablon güncellendi.", clock.instant());
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> deleteTemplate(@PathVariable Long id) {
		mealTemplateService.deleteTemplate(id);
		return ApiResponse.success(null, "Şablon silindi.", clock.instant());
	}

}
