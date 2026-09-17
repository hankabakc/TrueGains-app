package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.LogMealRequest;
import com.gym.v2.nutrition.dto.MealEntryResponse;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Öğün günlüğü (Meal Log) servis katmanı. Günlük tüketilen öğünlerin kaydedilmesini ve
 * yönetimini sağlar.
 *
 * Bulgu #1 (Instant Geçişi) kapsamında tüm zaman işlemleri güncellendi.
 */
@Service
public class MealLogService {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(MealLogService.class);

	private final MealEntryRepository mealEntryRepository;

	private final MealItemRepository mealItemRepository;

	private final FoodRepository foodRepository;

	private final RecipeRepository recipeRepository;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final NutrientCalculator nutrientCalculator;

	private final Clock clock;

	public MealLogService(MealEntryRepository mealEntryRepository, MealItemRepository mealItemRepository,
			FoodRepository foodRepository, RecipeRepository recipeRepository, UserContextService userContextService,
			NutritionMapper nutritionMapper, NutrientCalculator nutrientCalculator, Clock clock) {
		this.mealEntryRepository = mealEntryRepository;
		this.mealItemRepository = mealItemRepository;
		this.foodRepository = foodRepository;
		this.recipeRepository = recipeRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.nutrientCalculator = nutrientCalculator;
		this.clock = clock;
	}

	@Transactional
	public MealEntryResponse logMealEntry(LogMealRequest request) {
		AppUser user = userContextService.getCurrentUser();
		Instant takenAt = request.takenDatetime() != null ? request.takenDatetime() : clock.instant();

		// Gün aralığını hesapla (UTC Standartı)
		Instant startDay = takenAt.truncatedTo(ChronoUnit.DAYS);
		Instant endDay = startDay.plus(1, ChronoUnit.DAYS);

		MealEntry entry = mealEntryRepository
			.findByClientAndMealTypeAndDateRange(user, request.mealType(), startDay, endDay)
			.orElseGet(() -> {
				MealEntry newEntry = new MealEntry(user, takenAt, request.mealType());
				return mealEntryRepository.save(newEntry);
			});

		// Tekrar koruması (G-72): kuyruktan ya da zaman aşımında yeniden gelen kalem
		// ikinci kez yazılmaz.
		Set<String> seenLocalIds = entry.getItems()
			.stream()
			.map(MealItem::getLocalId)
			.filter(Objects::nonNull)
			.collect(Collectors.toCollection(HashSet::new));

		// Yeni kalemleri mevcut listeye ekliyoruz (Overwrite yerine Merge stratejisi)
		if (request.items() != null) {
			for (var itemReq : request.items()) {
				if (itemReq.amount() == null || itemReq.amount().compareTo(BigDecimal.ZERO) <= 0) {
					continue;
				}

				if (itemReq.localId() != null && !seenLocalIds.add(itemReq.localId())) {
					continue;
				}

				MealItem mealItem = new MealItem();
				mealItem.setMealEntry(entry);
				mealItem.setAmount(itemReq.amount());
				mealItem.setNote(itemReq.note());
				mealItem.setLocalId(itemReq.localId());

				Long recipeId = itemReq.recipeId();

				if (itemReq.foodId() != null) {
					Food food = foodRepository.findById(itemReq.foodId())
						.orElseThrow(() -> new NotFoundException("Besin bulunamadı: " + itemReq.foodId()));
					mealItem.setFood(food);
					nutrientCalculator.calculateMealItemNutrients(mealItem, food, user.getId());
				}
				else if (recipeId != null) {
					Recipe recipe = recipeRepository.findById(recipeId)
						.orElseThrow(() -> new NotFoundException("Tarif bulunamadı: " + recipeId));
					mealItem.setRecipe(recipe);
					nutrientCalculator.calculateMealItemNutrients(mealItem, recipe, user.getId());
				}

				entry.addItem(mealItem);
			}
		}

		nutrientCalculator.calculateMealEntryTotals(entry);
		return nutritionMapper.toMealEntryResponse(mealEntryRepository.saveAndFlush(entry), user.getId());
	}

	@Transactional(readOnly = true)
	public List<MealEntryResponse> getDailyMealEntries(LocalDate date) {
		AppUser currentUser = userContextService.getCurrentUser();
		// LocalDate'i Instant aralığına çevir
		Instant startOfDay = date.atStartOfDay(ZoneOffset.UTC).toInstant();
		Instant endOfDay = startOfDay.plus(1, ChronoUnit.DAYS);

		List<MealEntry> entries = mealEntryRepository.findDailyLogs(currentUser.getId(), startOfDay, endOfDay);
		return entries.stream().map(entry -> nutritionMapper.toMealEntryResponse(entry, currentUser.getId())).toList();
	}

	@Transactional
	public MealEntryResponse addFoodToMealLog(MealType mealType, Long foodId, BigDecimal amount,
			boolean ignoreOverride) {
		AppUser currentUser = userContextService.getCurrentUser();
		Instant now = clock.instant();
		Instant startOfDay = now.truncatedTo(ChronoUnit.DAYS);
		Instant endOfDay = startOfDay.plus(1, ChronoUnit.DAYS);

		List<MealEntry> todayEntries = mealEntryRepository.findDailyLogs(currentUser.getId(), startOfDay, endOfDay);
		MealEntry entry = todayEntries.stream().filter(e -> e.getMealType() == mealType).findFirst().orElseGet(() -> {
			MealEntry newEntry = new MealEntry(currentUser, now, mealType);
			return mealEntryRepository.save(newEntry);
		});

		Food food = foodRepository.findById(foodId)
			.orElseThrow(() -> new NotFoundException("Besin bulunamadı: " + foodId));

		MealItem item = new MealItem(entry, food, amount);
		nutrientCalculator.calculateMealItemNutrients(item, food, currentUser.getId());

		entry.addItem(item);

		nutrientCalculator.calculateMealEntryTotals(entry);
		return nutritionMapper.toMealEntryResponse(mealEntryRepository.saveAndFlush(entry), currentUser.getId());
	}

	@Transactional
	public void deleteMealEntry(Long entryId) {
		AppUser user = userContextService.getCurrentUser();
		MealEntry entry = mealEntryRepository.findById(entryId)
			.orElseThrow(() -> new NotFoundException("Öğün kaydı bulunamadı: " + entryId));
		if (!entry.getClient().getId().equals(user.getId())) {
			throw new BadRequestException("Bu kayıt size ait değil!");
		}
		mealEntryRepository.delete(entry);
	}

	@Transactional
	public Optional<MealEntryResponse> deleteMealItem(Long itemId) {
		AppUser user = userContextService.getCurrentUser();
		MealItem item = mealItemRepository.findById(itemId)
			.orElseThrow(() -> new NotFoundException("Öğün öğesi bulunamadı: " + itemId));
		MealEntry entry = item.getMealEntry();
		if (!entry.getClient().getId().equals(user.getId())) {
			throw new BadRequestException("Bu kayıt size ait değil!");
		}
		entry.removeItem(item);
		if (entry.getItems().isEmpty()) {
			mealEntryRepository.delete(entry);
			return Optional.empty();
		}
		MealEntry saved = mealEntryRepository.saveAndFlush(entry);
		return Optional.of(nutritionMapper.toMealEntryResponse(saved, user.getId()));
	}

}
