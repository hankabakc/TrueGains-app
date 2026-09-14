package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import com.gym.v2.nutrition.dto.NutritionDashboardResponse;
import com.gym.v2.nutrition.dto.UpdateNutritionGoalsRequest;
import com.gym.v2.nutrition.service.NutritionAnalyticsService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/nutrition/analytics")
public class NutritionAnalyticsController {

	private final NutritionAnalyticsService analyticsService;

	private final Clock clock;

	public NutritionAnalyticsController(NutritionAnalyticsService analyticsService, Clock clock) {
		this.analyticsService = analyticsService;
		this.clock = clock;
	}

	@GetMapping("/dashboard")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<NutritionDashboardResponse> getDashboard(@RequestParam(required = false) Long programId,
			@RequestParam(required = false) Long targetUserId) {
		NutritionDashboardResponse data = analyticsService.getDashboardData(programId, targetUserId);
		return ApiResponse.success(data, "Dashboard verileri başarıyla getirildi", clock.instant());
	}

	@PostMapping("/goals")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> updateGoals(@Valid @RequestBody UpdateNutritionGoalsRequest request) {
		analyticsService.updateNutritionGoals(request);
		return ApiResponse.success(null, "Beslenme hedefleri başarıyla güncellendi", clock.instant());
	}

}
