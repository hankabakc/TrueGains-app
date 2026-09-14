package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.RecipeResponse;
import com.gym.v2.nutrition.entity.Recipe;
import com.gym.v2.nutrition.repository.RecipeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Yemek Tarifi Servisi (RecipeService) Onaylı tariflerin listelenmesi ve aranması
 * işlemlerini yönetir.
 */
@Service
@Transactional(readOnly = true)
public class RecipeService {

	private static final Logger log = LoggerFactory.getLogger(RecipeService.class);

	private final RecipeRepository recipeRepository;

	private final NutritionMapper nutritionMapper;

	private final UserContextService userContextService;

	private final NutrientCalculator nutrientCalculator;

	public RecipeService(RecipeRepository recipeRepository, NutritionMapper nutritionMapper,
			UserContextService userContextService, NutrientCalculator nutrientCalculator) {
		this.recipeRepository = recipeRepository;
		this.nutritionMapper = nutritionMapper;
		this.userContextService = userContextService;
		this.nutrientCalculator = nutrientCalculator;
	}

	public List<RecipeResponse> searchRecipes(String query) {
		AppUser currentUser = userContextService.getCurrentUser();
		List<RecipeResponse> results = new java.util.ArrayList<>();

		List<Recipe> globalRecipes;
		if (query == null || query.isBlank()) {
			globalRecipes = recipeRepository.findAll();
		}
		else {
			globalRecipes = recipeRepository.searchRecipes(query);
		}

		for (Recipe r : globalRecipes) {
			results.add(nutrientCalculator.calculateRecipeResponse(r, currentUser.getId()));
		}

		return results;
	}

	public RecipeResponse getRecipeById(Long id) {
		AppUser currentUser = userContextService.getCurrentUser();
		Recipe recipe = recipeRepository.findById(id)
			.orElseThrow(() -> new RuntimeException("Tarif bulunamadı: " + id));
		return nutrientCalculator.calculateRecipeResponse(recipe, currentUser.getId());
	}

	public List<RecipeResponse> getRecipesByCategory(String category) {
		AppUser currentUser = userContextService.getCurrentUser();
		List<Recipe> recipes = recipeRepository.findByCategory(category);
		return recipes.stream().map(r -> nutrientCalculator.calculateRecipeResponse(r, currentUser.getId())).toList();
	}

}
