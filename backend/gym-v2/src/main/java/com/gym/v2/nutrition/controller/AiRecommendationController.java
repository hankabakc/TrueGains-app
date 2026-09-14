package com.gym.v2.nutrition.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Clock;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.service.UserService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.nutrition.dto.AiRecipeSuggestionResponse;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.dto.NutritionDashboardResponse;
import com.gym.v2.nutrition.dto.RecipeResponse;
import com.gym.v2.nutrition.service.DietIngredientService;
import com.gym.v2.nutrition.service.GeminiVisionService;
import com.gym.v2.nutrition.service.NutritionAnalyticsService;
import com.gym.v2.nutrition.service.RecipeService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Yapay Zeka Beslenme Önerileri Kontrolcüsü (AiRecommendationController)
 */
@RestController
@RequestMapping("/api/v1/nutrition/ai")
public class AiRecommendationController {

	private final GeminiVisionService geminiVisionService;

	private final DietIngredientService ingredientService;

	private final NutritionAnalyticsService analyticsService;

	private final RecipeService recipeService;

	private final UserService userService;

	private final ObjectMapper objectMapper;

	private final Clock clock;

	public AiRecommendationController(GeminiVisionService geminiVisionService, DietIngredientService ingredientService,
			NutritionAnalyticsService analyticsService, RecipeService recipeService, UserService userService,
			ObjectMapper objectMapper, Clock clock) {
		this.geminiVisionService = geminiVisionService;
		this.ingredientService = ingredientService;
		this.analyticsService = analyticsService;
		this.recipeService = recipeService;
		this.userService = userService;
		this.objectMapper = objectMapper;
		this.clock = clock;
	}

	@PostMapping("/suggest-recipe")
	public ApiResponse<AiRecipeSuggestionResponse> suggestRecipe(@RequestParam(required = false) Long programId) {
		AppUser user = userService.getCurrentUser();

		// Gerekli verileri topla
		NutritionDashboardResponse dashboard = analyticsService.getDashboardData(programId, null);
		List<RecipeResponse> availableRecipes = recipeService.searchRecipes(null);

		AiRecipeSuggestionResponse suggestion = geminiVisionService.suggestRecipe(user, dashboard, availableRecipes);
		return ApiResponse.success(suggestion, "Yapay zeka size özel bir tarif hazırladı!", clock.instant());
	}

	@GetMapping("/last-suggestion")
	public ApiResponse<AiRecipeSuggestionResponse> getLastSuggestion() {
		AppUser user = userService.getCurrentUser();

		if (user.getLastAiRecipeSuggestion() == null) {
			return ApiResponse.success(null, "Henüz bir öneri bulunmuyor.", clock.instant());
		}

		try {
			AiRecipeSuggestionResponse suggestion = objectMapper.readValue(user.getLastAiRecipeSuggestion(),
					AiRecipeSuggestionResponse.class);
			return ApiResponse.success(suggestion, "Son öneri getirildi.", clock.instant());
		}
		catch (Exception e) {
			return ApiResponse.success(null, "Öneri parse edilemedi.", clock.instant());
		}
	}

	@PostMapping("/save-recipe")
	public ApiResponse<DietProgramResponse> addAiRecipeToMeal(@RequestParam Long mealId, @RequestParam Long recipeId) {
		// AI önerisi varsayılan olarak 1 porsiyon (BigDecimal.ONE) olarak eklenir.
		DietProgramResponse updatedProgram = ingredientService.addRecipeToMeal(mealId, recipeId,
				java.math.BigDecimal.ONE);
		return ApiResponse.success(updatedProgram, "Tarif başarıyla programa eklendi.", clock.instant());
	}

}
