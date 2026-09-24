package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.ConflictException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.DietProgramDocumentRequest;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.entity.DietDay;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.Meal;
import com.gym.v2.nutrition.entity.MealIngredient;
import com.gym.v2.nutrition.entity.Recipe;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.RecipeRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * G-76: Diyet planının tamamını tek belgede kaydeden servis.
 */
@Service
public class DietDocumentService {

	private final DietProgramRepository programRepository;

	private final FoodRepository foodRepository;

	private final RecipeRepository recipeRepository;

	private final DietProgramService programService;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final Clock clock;

	public DietDocumentService(DietProgramRepository programRepository, FoodRepository foodRepository,
			RecipeRepository recipeRepository, DietProgramService programService, UserContextService userContextService,
			NutritionMapper nutritionMapper, Clock clock) {
		this.programRepository = programRepository;
		this.foodRepository = foodRepository;
		this.recipeRepository = recipeRepository;
		this.programService = programService;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.clock = clock;
	}

	@Transactional
	public DietProgramResponse saveDocument(Long id, DietProgramDocumentRequest request) {
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		if (request.editId() != null && request.editId().equals(program.getLastEditId())) {
			return nutritionMapper.toProgramResponse(program, currentUser.getId());
		}

		if (!request.version().equals(program.getVersion())) {
			throw new ConflictException(
					"Diyet planı başka bir cihazda değiştirilmiş; sunucudaki hâli geçerli. Planı yenileyip tekrar düzenleyin.");
		}

		Map<Long, DietDay> dayMap = new HashMap<>();
		for (DietDay day : program.getDietDays()) {
			dayMap.put(day.getId(), day);
		}

		List<Long> newFoodIds = new ArrayList<>();
		List<Long> newRecipeIds = new ArrayList<>();
		validateDocumentStructure(request, dayMap, newFoodIds, newRecipeIds);

		Map<Long, Food> foodMap = fetchFoods(newFoodIds);
		Map<Long, Recipe> recipeMap = fetchRecipes(newRecipeIds);

		applyDocumentChanges(program, request, dayMap, foodMap, recipeMap);

		program.setLastEditId(request.editId());
		program.onUpdate(clock.instant());
		DietProgram saved = programRepository.saveAndFlush(program);
		programService.handleSyncAndNotification(saved);
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	private void validateDocumentStructure(DietProgramDocumentRequest request, Map<Long, DietDay> dayMap,
			List<Long> newFoodIds, List<Long> newRecipeIds) {
		Set<Long> docDayIds = new HashSet<>();
		for (DietProgramDocumentRequest.DayDoc dayDoc : request.days()) {
			if (!docDayIds.add(dayDoc.id())) {
				throw new BadRequestException("Belge programın günlerini birebir içermeli.");
			}
		}

		if (docDayIds.size() != dayMap.size() || !docDayIds.equals(dayMap.keySet())) {
			throw new BadRequestException("Belge programın günlerini birebir içermeli.");
		}

		for (DietProgramDocumentRequest.DayDoc dayDoc : request.days()) {
			DietDay day = dayMap.get(dayDoc.id());
			Map<Long, Meal> mealMap = new HashMap<>();
			for (Meal meal : day.getMeals()) {
				mealMap.put(meal.getId(), meal);
			}

			Set<Long> docMealIds = new HashSet<>();
			for (DietProgramDocumentRequest.MealDoc mealDoc : dayDoc.meals()) {
				if (!docMealIds.add(mealDoc.id()) || !mealMap.containsKey(mealDoc.id())) {
					throw new BadRequestException("Öğün bu güne ait değil: " + mealDoc.id());
				}

				validateIngredients(mealMap.get(mealDoc.id()), mealDoc, newFoodIds, newRecipeIds);
			}
		}

		if (request.name() == null || request.name().trim().isEmpty()) {
			throw new BadRequestException("Program adı boş olamaz.");
		}
	}

	private void validateIngredients(Meal meal, DietProgramDocumentRequest.MealDoc mealDoc, List<Long> newFoodIds,
			List<Long> newRecipeIds) {
		Map<Long, MealIngredient> ingMap = new HashMap<>();
		for (MealIngredient ing : meal.getIngredients()) {
			ingMap.put(ing.getId(), ing);
		}

		Set<Long> docIngIds = new HashSet<>();
		for (DietProgramDocumentRequest.IngredientDoc ingDoc : mealDoc.ingredients()) {
			if (ingDoc.id() != null) {
				if (!docIngIds.add(ingDoc.id()) || !ingMap.containsKey(ingDoc.id())) {
					throw new BadRequestException("Besin kaydı bu öğüne ait değil: " + ingDoc.id());
				}
			}
			else {
				boolean hasFood = ingDoc.foodId() != null;
				boolean hasRecipe = ingDoc.recipeId() != null;
				if (hasFood == hasRecipe) {
					throw new BadRequestException("Her yeni kayıtta foodId ya da recipeId zorunludur.");
				}
				if (hasFood) {
					newFoodIds.add(ingDoc.foodId());
				}
				else {
					newRecipeIds.add(ingDoc.recipeId());
				}
			}
		}
	}

	private Map<Long, Food> fetchFoods(List<Long> newFoodIds) {
		Map<Long, Food> foodMap = new HashMap<>();
		if (!newFoodIds.isEmpty()) {
			List<Food> foods = foodRepository.findAllById(newFoodIds);
			for (Food f : foods) {
				foodMap.put(f.getId(), f);
			}
			for (Long fid : newFoodIds) {
				if (!foodMap.containsKey(fid)) {
					throw new NotFoundException("Besin bulunamadı: " + fid);
				}
			}
		}
		return foodMap;
	}

	private Map<Long, Recipe> fetchRecipes(List<Long> newRecipeIds) {
		Map<Long, Recipe> recipeMap = new HashMap<>();
		if (!newRecipeIds.isEmpty()) {
			List<Recipe> recipes = recipeRepository.findAllById(newRecipeIds);
			for (Recipe r : recipes) {
				recipeMap.put(r.getId(), r);
			}
			for (Long rid : newRecipeIds) {
				if (!recipeMap.containsKey(rid)) {
					throw new NotFoundException("Tarif bulunamadı: " + rid);
				}
			}
		}
		return recipeMap;
	}

	private void applyDocumentChanges(DietProgram program, DietProgramDocumentRequest request,
			Map<Long, DietDay> dayMap, Map<Long, Food> foodMap, Map<Long, Recipe> recipeMap) {
		program.setName(request.name().trim());
		programService.applyGoals(program, request.goals());

		for (DietProgramDocumentRequest.DayDoc dayDoc : request.days()) {
			DietDay day = dayMap.get(dayDoc.id());
			Set<Long> requestedMealIds = new HashSet<>();
			for (DietProgramDocumentRequest.MealDoc md : dayDoc.meals()) {
				requestedMealIds.add(md.id());
			}
			day.getMeals().removeIf(m -> !requestedMealIds.contains(m.getId()));

			Map<Long, Meal> currentMealMap = new HashMap<>();
			for (Meal m : day.getMeals()) {
				currentMealMap.put(m.getId(), m);
			}

			for (DietProgramDocumentRequest.MealDoc mealDoc : dayDoc.meals()) {
				Meal meal = currentMealMap.get(mealDoc.id());
				applyMealIngredientChanges(meal, mealDoc, foodMap, recipeMap);
			}
		}
	}

	private void applyMealIngredientChanges(Meal meal, DietProgramDocumentRequest.MealDoc mealDoc,
			Map<Long, Food> foodMap, Map<Long, Recipe> recipeMap) {
		Set<Long> requestedIngIds = new HashSet<>();
		for (DietProgramDocumentRequest.IngredientDoc idoc : mealDoc.ingredients()) {
			if (idoc.id() != null) {
				requestedIngIds.add(idoc.id());
			}
		}
		meal.getIngredients().removeIf(i -> !requestedIngIds.contains(i.getId()));

		Map<Long, MealIngredient> currentIngMap = new HashMap<>();
		for (MealIngredient i : meal.getIngredients()) {
			currentIngMap.put(i.getId(), i);
		}

		for (DietProgramDocumentRequest.IngredientDoc ingDoc : mealDoc.ingredients()) {
			if (ingDoc.id() != null) {
				MealIngredient ing = currentIngMap.get(ingDoc.id());
				ing.setAmount(ingDoc.amount());
				ing.setNote(ingDoc.note());
				ing.setIgnoreOverride(Boolean.TRUE.equals(ingDoc.ignoreOverride()));
			}
			else if (ingDoc.foodId() != null) {
				Food food = foodMap.get(ingDoc.foodId());
				MealIngredient newIng = new MealIngredient(meal, food, ingDoc.amount(), ingDoc.note(),
						Boolean.TRUE.equals(ingDoc.ignoreOverride()));
				meal.getIngredients().add(newIng);
			}
			else {
				Recipe recipe = recipeMap.get(ingDoc.recipeId());
				MealIngredient newIng = new MealIngredient(meal, recipe, ingDoc.amount(), ingDoc.note());
				meal.getIngredients().add(newIng);
			}
		}
	}

}
