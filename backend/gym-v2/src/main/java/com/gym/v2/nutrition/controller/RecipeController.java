package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import com.gym.v2.nutrition.dto.RecipeResponse;
import com.gym.v2.nutrition.service.RecipeService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Yemek Tarifi Kontrolcüsü (RecipeController)
 */
@RestController
@RequestMapping("/api/v1/nutrition/recipes")
public class RecipeController {

	private static final Logger log = LoggerFactory.getLogger(RecipeController.class);

	private final RecipeService recipeService;

	private final Clock clock;

	public RecipeController(RecipeService recipeService, Clock clock) {
		this.recipeService = recipeService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<List<RecipeResponse>> getAllRecipes(@RequestParam(required = false) String query) {
		List<RecipeResponse> recipes = recipeService.searchRecipes(query);
		return ApiResponse.success(recipes, "Tarifler listelendi.", clock.instant());
	}

	@GetMapping("/{id}")
	public ApiResponse<RecipeResponse> getRecipeById(@PathVariable Long id) {
		RecipeResponse recipe = recipeService.getRecipeById(id);
		log.info("[RECIPE-DEBUG] GetByID Result: ID={}, Name={}", recipe.id(), recipe.name());
		return ApiResponse.success(recipe, "Tarif detayları getirildi.", clock.instant());
	}

	@GetMapping("/category/{category}")
	public ApiResponse<List<RecipeResponse>> getRecipesByCategory(@PathVariable String category) {
		List<RecipeResponse> recipes = recipeService.getRecipesByCategory(category);
		return ApiResponse.success(recipes, "Kategoriye göre tarifler listelendi.", clock.instant());
	}

}
