package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.BulkIngredientRequest;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.dto.RecipeRequest;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealIngredientRepository;
import com.gym.v2.nutrition.repository.MealRepository;
import com.gym.v2.nutrition.repository.RecipeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.gym.v2.nutrition.event.DietTemplateUpdatedEvent;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/**
 * DietIngredientService - Manages meal items and ingredients (add, delete, update).
 * Adheres to SRP by focusing on meal-level modifications.
 */
@Service
public class DietIngredientService {

	private static final Logger log = LoggerFactory.getLogger(DietIngredientService.class);

	private final MealRepository mealRepository;

	private final MealIngredientRepository ingredientRepository;

	private final FoodRepository foodRepository;

	private final RecipeRepository recipeRepository;

	private final DietProgramService programService;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final ApplicationEventPublisher eventPublisher;

	private final SimpMessagingTemplate messagingTemplate;

	public DietIngredientService(MealRepository mealRepository, MealIngredientRepository ingredientRepository,
			FoodRepository foodRepository, RecipeRepository recipeRepository, DietProgramService programService,
			UserContextService userContextService, NutritionMapper nutritionMapper,
			ApplicationEventPublisher eventPublisher, SimpMessagingTemplate messagingTemplate) {
		this.mealRepository = mealRepository;
		this.ingredientRepository = ingredientRepository;
		this.foodRepository = foodRepository;
		this.recipeRepository = recipeRepository;
		this.programService = programService;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.eventPublisher = eventPublisher;
		this.messagingTemplate = messagingTemplate;
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
		// kullanıcı
		// 10 besin ekleyip 7'sinin eklendiğini ancak sayarak fark ediyordu. Tekil uç
		// (`addIngredient`) aynı durumların hepsinde zaten hata fırlatıyor.
		for (var req : requests) {
			if (req.amount() == null || req.amount().compareTo(BigDecimal.ZERO) <= 0) {
				throw new BadRequestException("Miktar sıfırdan büyük olmalıdır!");
			}

			if (req.recipeId() != null) {
				Recipe recipe = recipeRepository.findById(req.recipeId())
					.orElseThrow(() -> new NotFoundException("Tarif bulunamadı: " + req.recipeId()));
				meal.getIngredients().add(new MealIngredient(meal, recipe, req.amount(), req.note()));
			}
			else if (req.foodId() != null) {
				Food food = foodRepository.findById(req.foodId())
					.orElseThrow(() -> new NotFoundException("Besin bulunamadı: " + req.foodId()));
				meal.getIngredients()
					.add(new MealIngredient(meal, food, req.amount(), req.note(), req.ignoreOverride()));
			}
			else {
				throw new BadRequestException("Her kayıtta foodId veya recipeId zorunludur.");
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
			Food food = foodRepository.findById(foodId)
				.orElseThrow(() -> new NotFoundException("Besin bulunamadı: " + foodId));
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
		if (program.isTemplate()) {
			eventPublisher.publishEvent(new DietTemplateUpdatedEvent(program.getId()));
		}
		else if (program.getOwner() != null) {
			AppUser currentUser = userContextService.getCurrentUser();
			// Sadece güncellemeyi yapan kişi sporcunun kendisi değilse WebSocket
			// tetiklenir
			if (!program.getOwner().getId().equals(currentUser.getId())) {
				messagingTemplate.convertAndSend("/topic/diet/" + program.getOwner().getId(), "REFRESH_REQUIRED");
			}
		}
	}

}
