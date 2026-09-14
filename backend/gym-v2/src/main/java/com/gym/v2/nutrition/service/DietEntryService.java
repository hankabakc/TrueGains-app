package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * DietEntryService - Günlük diyet günlüğü yönetimi. SRP uyumlu hale getirildi, mapping
 * işlemleri NutritionMapper ve NutrientCalculator'a devredildi.
 */
@Service
public class DietEntryService {

	private final MealEntryRepository mealEntryRepository;

	private final DietProgramRepository dietProgramRepository;

	private final MealRepository mealRepository;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final NutrientCalculator nutrientCalculator;

	private final Clock clock;

	public DietEntryService(MealEntryRepository mealEntryRepository, DietProgramRepository dietProgramRepository,
			MealRepository mealRepository, UserContextService userContextService, NutritionMapper nutritionMapper,
			NutrientCalculator nutrientCalculator, Clock clock) {
		this.mealEntryRepository = mealEntryRepository;
		this.dietProgramRepository = dietProgramRepository;
		this.mealRepository = mealRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.nutrientCalculator = nutrientCalculator;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public DailyDietLogResponse getDailyLog(LocalDate date) {
		AppUser user = userContextService.getCurrentUser();
		Instant start = date.atStartOfDay(ZoneOffset.UTC).toInstant();
		Instant end = start.plus(1, java.time.temporal.ChronoUnit.DAYS);

		List<MealEntry> logs = mealEntryRepository.findDailyLogs(user.getId(), start, end);
		DietProgram program = dietProgramRepository.findByOwnerIdAndMainTrue(user.getId()).orElse(null);

		List<PlannedMealResponse> plannedMeals = getPlannedMealsForDate(date, user, logs, program);

		List<MealEntryResponse> extraEntries = logs.stream()
			.filter(l -> l.getPlannedMealId() == null)
			.map(l -> nutritionMapper.toMealEntryResponse(l, user.getId()))
			.toList();

		return new DailyDietLogResponse(plannedMeals, extraEntries);
	}

	private List<PlannedMealResponse> getPlannedMealsForDate(LocalDate date, AppUser user, List<MealEntry> logs,
			DietProgram program) {
		if (program == null || program.getDietDays().isEmpty()) {
			return new ArrayList<>();
		}

		int dayIndex = (date.getDayOfWeek().getValue() - 1) % program.getDietDays().size();
		DietDay dietDay = program.getDietDays().get(dayIndex);

		return dietDay.getMeals().stream().map(meal -> mapToPlannedMealResponse(meal, logs, user)).toList();
	}

	private PlannedMealResponse mapToPlannedMealResponse(Meal meal, List<MealEntry> logs, AppUser user) {
		Optional<MealEntry> matchedLog = logs.stream()
			.filter(l -> meal.getId().equals(l.getPlannedMealId()))
			.findFirst();

		List<MealIngredientResponse> ingredientResponses = meal.getIngredients()
			.stream()
			.map(ing -> nutrientCalculator.toIngredientResponse(ing, user.getId()))
			.toList();

		List<Long> consumedIngredientIds = new java.util.ArrayList<>();
		if (matchedLog.isPresent()) {
			MealEntry entry = matchedLog.get();
			// Her log öğesini yalnızca BİR planlı malzemeyle eşleştir (eşleşeni havuzdan
			// çıkar).
			// Aksi halde aynı besin öğünde birden çok kez yer alıyorsa, biri yendiğinde
			// aynı
			// besinli tüm malzemeler işaretlenir ve işaret bir daha kaldırılamaz.
			java.util.List<MealItem> remainingItems = new java.util.ArrayList<>(entry.getItems());
			for (MealIngredient ing : meal.getIngredients()) {
				MealItem matchedItem = remainingItems.stream().filter(item -> {
					if (ing.getFood() != null && item.getFood() != null) {
						return ing.getFood().getId().equals(item.getFood().getId());
					}
					if (ing.getRecipe() != null && item.getRecipe() != null) {
						return ing.getRecipe().getId().equals(item.getRecipe().getId());
					}
					return false;
				}).findFirst().orElse(null);
				if (matchedItem != null) {
					consumedIngredientIds.add(ing.getId());
					remainingItems.remove(matchedItem);
				}
			}
		}

		return new PlannedMealResponse(meal.getId(), meal.getMealType().name(), ingredientResponses,
				matchedLog.isPresent(), matchedLog.map(MealEntry::getId).orElse(null), consumedIngredientIds);
	}

	@Transactional
	public MealEntryResponse togglePlannedMeal(LocalDate date, Long mealId, boolean consumed,
			java.util.List<Long> ingredientIds) {
		AppUser user = userContextService.getCurrentUser();

		Instant start = date.atStartOfDay(ZoneOffset.UTC).toInstant();
		Instant end = start.plus(1, java.time.temporal.ChronoUnit.DAYS);

		List<MealEntry> existingLogs = mealEntryRepository.findDailyLogs(user.getId(), start, end)
			.stream()
			.filter(l -> mealId.equals(l.getPlannedMealId()))
			.toList();

		if (!consumed) {
			if (!existingLogs.isEmpty()) {
				mealEntryRepository.deleteAll(existingLogs);
			}
			return null;
		}

		if (!existingLogs.isEmpty()) {
			MealEntry entry = existingLogs.get(0);
			if (existingLogs.size() > 1) {
				mealEntryRepository.deleteAll(existingLogs.subList(1, existingLogs.size()));
			}
			entry.getItems().clear();

			Meal plannedMeal = mealRepository.findById(mealId)
				.orElseThrow(() -> new NotFoundException("Programdaki öğün bulunamadı!"));

			if (!plannedMeal.getDietDay().getDietProgram().getOwner().getId().equals(user.getId())) {
				throw new BadRequestException("Bu öğün size ait değil!");
			}

			for (MealIngredient ing : plannedMeal.getIngredients()) {
				if (isValidAndSelected(ing, ingredientIds)) {
					MealItem item = createMealItemFromIngredient(ing, entry, user.getId());
					entry.addItem(item);
				}
			}
			nutrientCalculator.calculateMealEntryTotals(entry);
			MealEntry saved = mealEntryRepository.save(entry);
			return nutritionMapper.toMealEntryResponse(saved, user.getId());
		}

		Meal plannedMeal = mealRepository.findById(mealId)
			.orElseThrow(() -> new NotFoundException("Programdaki öğün bulunamadı!"));

		if (!plannedMeal.getDietDay().getDietProgram().getOwner().getId().equals(user.getId())) {
			throw new BadRequestException("Bu öğün size ait değil!");
		}

		MealEntry entry = createMealEntryFromPlanned(plannedMeal, user, ingredientIds, date);
		nutrientCalculator.calculateMealEntryTotals(entry);
		MealEntry saved = mealEntryRepository.save(entry);

		return nutritionMapper.toMealEntryResponse(saved, user.getId());
	}

	private MealEntry createMealEntryFromPlanned(Meal plannedMeal, AppUser user, List<Long> ingredientIds,
			LocalDate date) {
		Instant takenTime = date.atStartOfDay(ZoneOffset.UTC).toInstant();
		// Eğer bugün için işlem yapılıyorsa anlık saati kullan, geçmiş/gelecek ise gün
		// başlangıcını ata
		if (date.equals(LocalDate.now(clock))) {
			takenTime = clock.instant();
		}

		MealEntry entry = new MealEntry(user, takenTime, plannedMeal.getMealType());
		entry.setPlannedMealId(plannedMeal.getId());

		for (MealIngredient ing : plannedMeal.getIngredients()) {
			if (isValidAndSelected(ing, ingredientIds)) {
				MealItem item = createMealItemFromIngredient(ing, entry, user.getId());
				entry.addItem(item);
			}
		}
		return entry;
	}

	private boolean isValidAndSelected(MealIngredient ing, List<Long> ingredientIds) {
		if (ing.getFood() == null && ing.getRecipe() == null) {
			return false;
		}
		return ingredientIds == null || ingredientIds.isEmpty() || ingredientIds.contains(ing.getId());
	}

	private MealItem createMealItemFromIngredient(MealIngredient ing, MealEntry entry, Long userId) {
		MealItem item = new MealItem();
		item.setMealEntry(entry);
		item.setFood(ing.getFood());
		item.setRecipe(ing.getRecipe());
		item.setAmount(ing.getAmount());
		item.setNote(ing.getNote());

		if (ing.getFood() != null) {
			nutrientCalculator.calculateMealItemNutrients(item, ing.getFood(), userId);
		}
		else {
			nutrientCalculator.calculateMealItemNutrients(item, ing.getRecipe(), userId);
		}
		return item;
	}

}
