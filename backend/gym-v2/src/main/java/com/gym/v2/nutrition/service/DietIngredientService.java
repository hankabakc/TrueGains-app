package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.BulkIngredientRequest;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.dto.RecipeRequest;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.MealIngredientRepository;
import com.gym.v2.nutrition.repository.MealRepository;
import com.gym.v2.nutrition.repository.RecipeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DietIngredientService - Manages meal items and ingredients (add, delete, update).
 * Adheres to SRP by focusing on meal-level modifications.
 */
@Service
public class DietIngredientService {

	private static final Logger log = LoggerFactory.getLogger(DietIngredientService.class);

	private final MealRepository mealRepository;

	private final MealIngredientRepository ingredientRepository;

	private final FoodService foodService;

	private final RecipeRepository recipeRepository;

	private final DietProgramService programService;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final Clock clock;

	public DietIngredientService(MealRepository mealRepository, MealIngredientRepository ingredientRepository,
			FoodService foodService, RecipeRepository recipeRepository, DietProgramService programService,
			UserContextService userContextService, NutritionMapper nutritionMapper, Clock clock) {
		this.mealRepository = mealRepository;
		this.ingredientRepository = ingredientRepository;
		this.foodService = foodService;
		this.recipeRepository = recipeRepository;
		this.programService = programService;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.clock = clock;
	}

	@Transactional
	public DietProgramResponse addIngredientsBulk(Long mealId, List<BulkIngredientRequest> requests) {
		Meal meal = mealRepository.findById(mealId)
			.orElseThrow(() -> new NotFoundException("Öğün bulunamadı: " + mealId));

		DietProgram program = meal.getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		// Geçersiz kayıtlar SESSİZCE atlanmaz. Önceden sıfır miktar `continue` ile,
		// bulunamayan besin/tarif `ifPresent` ile düşüyordu ve uç 200 dönüyordu:
		// kullanıcı 10 besin ekleyip 7'sinin eklendiğini ancak sayarak fark ediyordu.
		// Tekil uç (`addIngredient`) aynı durumların hepsinde zaten hata fırlatıyor.
		List<Long> foodIds = new ArrayList<>();
		List<Long> recipeIds = new ArrayList<>();
		for (var req : requests) {
			if (req.amount() == null || req.amount().compareTo(BigDecimal.ZERO) <= 0) {
				throw new BadRequestException("Miktar sıfırdan büyük olmalıdır!");
			}
			if (req.recipeId() != null) {
				recipeIds.add(req.recipeId());
			}
			else if (req.foodId() != null) {
				foodIds.add(req.foodId());
			}
			else {
				throw new BadRequestException("Her kayıtta foodId veya recipeId zorunludur.");
			}
		}

		Map<Long, Food> foods = foodService.findVisibleFoods(foodIds, currentUser);
		Map<Long, Recipe> recipes = new HashMap<>();
		for (Recipe recipe : recipeRepository.findAllById(recipeIds)) {
			recipes.put(recipe.getId(), recipe);
		}
		for (Long recipeId : recipeIds) {
			if (!recipes.containsKey(recipeId)) {
				throw new NotFoundException("Tarif bulunamadı: " + recipeId);
			}
		}

		for (var req : requests) {
			if (req.recipeId() != null) {
				meal.getIngredients()
					.add(new MealIngredient(meal, recipes.get(req.recipeId()), req.amount(), req.note()));
			}
			else {
				meal.getIngredients()
					.add(new MealIngredient(meal, foods.get(req.foodId()), req.amount(), req.note(),
							req.ignoreOverride()));
			}
		}

		mealRepository.save(meal);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse addIngredient(Long mealId, Long foodId, BigDecimal amount, String note,
			boolean ignoreOverride, Long recipeId, Long userRecipeId) {
		if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
			throw new BadRequestException("Miktar sıfırdan büyük olmalıdır!");
		}

		Meal meal = mealRepository.findById(mealId)
			.orElseThrow(() -> new NotFoundException("Öğün bulunamadı: " + mealId));

		DietProgram program = meal.getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		Long effectiveRecipeId = recipeId != null ? recipeId : userRecipeId;
		MealIngredient ingredient;
		if (effectiveRecipeId != null) {
			Recipe recipe = recipeRepository.findById(effectiveRecipeId)
				.orElseThrow(() -> new NotFoundException("Tarif bulunamadı: " + effectiveRecipeId));
			ingredient = new MealIngredient(meal, recipe, amount, note);
		}
		else {
			if (foodId == null) {
				throw new BadRequestException("foodId veya recipeId zorunludur.");
			}
			Food food = foodService.findVisibleFoods(List.of(foodId), currentUser).get(foodId);
			ingredient = new MealIngredient(meal, food, amount, note, ignoreOverride);
		}

		meal.getIngredients().add(ingredient);
		ingredientRepository.save(ingredient);
		log.info("[DIET] Besin eklendi. IngredientID: {}, MealID: {}, Miktar: {}", ingredient.getId(), mealId, amount);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse addRecipeToMeal(Long mealId, Long recipeId, BigDecimal amount) {
		if (amount != null && amount.compareTo(BigDecimal.ZERO) <= 0) {
			throw new BadRequestException("Porsiyon miktarı sıfırdan büyük olmalıdır!");
		}

		Meal meal = mealRepository.findById(mealId)
			.orElseThrow(() -> new NotFoundException("Öğün bulunamadı: " + mealId));

		DietProgram program = meal.getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		Recipe recipe = recipeRepository.findById(recipeId)
			.orElseThrow(() -> new NotFoundException("Tarif bulunamadı: " + recipeId));

		MealIngredient mi = new MealIngredient(meal, recipe, amount != null ? amount : BigDecimal.ONE, "AI Önerisi");
		ingredientRepository.save(mi);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse deleteMeal(Long mealId) {
		Meal meal = mealRepository.findById(mealId)
			.orElseThrow(() -> new NotFoundException("Öğün bulunamadı: " + mealId));

		DietProgram program = meal.getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		meal.getDietDay().getMeals().remove(meal);
		mealRepository.delete(meal);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse deleteIngredient(Long ingredientId) {
		MealIngredient ingredient = ingredientRepository.findById(ingredientId)
			.orElseThrow(() -> new NotFoundException("Besin kaydı bulunamadı: " + ingredientId));

		DietProgram program = ingredient.getMeal().getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		ingredient.getMeal().getIngredients().remove(ingredient);
		ingredientRepository.delete(ingredient);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse updateIngredientAmount(Long ingredientId, BigDecimal amount) {
		if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
			throw new BadRequestException("Miktar sıfırdan büyük olmalıdır!");
		}

		MealIngredient ingredient = ingredientRepository.findById(ingredientId)
			.orElseThrow(() -> new NotFoundException("Besin kaydı bulunamadı: " + ingredientId));

		DietProgram program = ingredient.getMeal().getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		ingredient.setAmount(amount);
		ingredientRepository.save(ingredient);

		log.info("[DIET] Besin miktarı güncellendi. IngredientID: {}, Yeni miktar: {}", ingredientId, amount);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse updateRecipeIngredient(Long ingredientId, RecipeRequest request) {
		MealIngredient ingredient = ingredientRepository.findById(ingredientId)
			.orElseThrow(() -> new NotFoundException("Besin kaydı bulunamadı: " + ingredientId));

		DietProgram program = ingredient.getMeal().getDietDay().getDietProgram();
		AppUser currentUser = userContextService.getCurrentUser();
		programService.validateOwnershipAndModifiability(program, currentUser);

		if (ingredient.getRecipe() == null) {
			throw new BadRequestException("Bu kayıt bir tarif değil.");
		}

		// Tarif adı DEĞİŞTİRİLMEZ. `Recipe` ortak katalog varlığıdır: sahiplik alanı yok
		// (ne owner, ne createdBy) ve uygulamada tarif oluşturan hiçbir kod yolu
		// bulunmuyor
		// — kayıtlar migration'lardan geliyor. Buradaki tek yetki kontrolü kullanıcının
		// DİYET PROGRAMINA sahip olduğunu doğruluyor, TARİFE değil. Daha önce burada
		// `ingredient.getRecipe().setName(...)` vardı; Hibernate kirli-kontrolle ortak
		// kaydı da güncellediği için bir kullanıcının kendi öğününde yaptığı yeniden
		// adlandırma sistemdeki HERKESİN tarif listesini değiştiriyordu.
		if (request.name() != null && !request.name().equals(ingredient.getRecipe().getName())) {
			throw new BadRequestException(
					"Tarif adı değiştirilemez: tarifler tüm kullanıcıların paylaştığı ortak listeden gelir.");
		}

		ingredientRepository.save(ingredient);
		handleSyncAndNotification(program);
		return nutritionMapper.toProgramResponse(program, currentUser.getId());
	}

	private void handleSyncAndNotification(DietProgram program) {
		// G-76: besin değişikliği programın kendi alanına dokunmaz; @Version ancak
		// program kirletilince ilerler. G-90: sürüm flush'ta artar — yanıt flush'tan
		// önce kurulursa istemci eski sürümü alır ve sonraki belgesi 409 alır.
		program.onUpdate(clock.instant());
		mealRepository.flush();
		programService.handleSyncAndNotification(program);
	}

}
