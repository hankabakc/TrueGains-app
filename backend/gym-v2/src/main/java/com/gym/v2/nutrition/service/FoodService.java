package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.FoodCreateRequest;
import com.gym.v2.nutrition.dto.FoodOverrideRequest;
import com.gym.v2.nutrition.dto.FoodResponse;
import com.gym.v2.nutrition.dto.MealHistoryResponse;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.entity.UserFoodOverride;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealIngredientRepository;
import com.gym.v2.nutrition.repository.MealItemRepository;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * FoodService - Besin Modülü İş Mantığı.
 */
@Service
public class FoodService {

	/**
	 * Arama sonucu tavanı. Besin tablosu kullanıcı üretimiyle büyüyor; tavansız arama tek
	 * harflik sorguda tüm tabloyu döndürür.
	 */
	private static final int SEARCH_RESULT_LIMIT = 50;

	private final FoodRepository foodRepository;

	private final UserFoodOverrideRepository overrideRepository;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final MealItemRepository mealItemRepository;

	private final MealIngredientRepository mealIngredientRepository;

	private final ClientRepository clientRepository;

	private final Clock clock;

	public FoodService(FoodRepository foodRepository, UserFoodOverrideRepository overrideRepository,
			UserContextService userContextService, NutritionMapper nutritionMapper,
			MealItemRepository mealItemRepository, MealIngredientRepository mealIngredientRepository,
			ClientRepository clientRepository, Clock clock) {
		this.foodRepository = foodRepository;
		this.overrideRepository = overrideRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.mealItemRepository = mealItemRepository;
		this.mealIngredientRepository = mealIngredientRepository;
		this.clientRepository = clientRepository;
		this.clock = clock;
	}

	private List<Long> resolveVisibleCreatorIds(AppUser user) {
		List<Long> ids = new ArrayList<>();
		ids.add(user.getId());
		if (user.getRole() == UserRole.CLIENT) {
			clientRepository.findByUserId(user.getId()).map(ClientEntity::getCoachId).ifPresent(cid -> {
				if (cid != null) {
					ids.add(cid);
				}
			});
		}
		else if (user.getRole() == UserRole.COACH) {
			clientRepository.findAllByCoachId(user.getId()).forEach(c -> ids.add(c.getUserId()));
		}
		return ids;
	}

	/**
	 * Sadece yerel veritabanında arama yapar.
	 * @param query Arama terimi
	 * @return FoodResponse listesi
	 */
	@Transactional(readOnly = true)
	public List<FoodResponse> searchFood(String query) {
		AppUser currentUser = userContextService.getCurrentUser();
		List<Food> localFoods = foodRepository.searchVisible(query, resolveVisibleCreatorIds(currentUser),
				PageRequest.of(0, SEARCH_RESULT_LIMIT));

		java.util.Map<Long, UserFoodOverride> overrides = loadOverrides(currentUser.getId(), localFoods);

		List<FoodResponse> results = new ArrayList<>();
		for (Food food : localFoods) {
			UserFoodOverride override = overrides.get(food.getId());
			if (override != null) {
				// Her iki versiyonu da ekle: Önce özelleştirilmiş olan
				results.add(convertToResponse(food, override));
				// Sonra orijinal olan
				boolean isBrandVerified = food.getBrand() != null && !food.getBrand().isEmpty();
				results.add(nutritionMapper.toFoodResponse(food, false, isBrandVerified));
			}
			else {
				results.add(convertToResponse(food, (UserFoodOverride) null));
			}
		}
		return results;
	}

	@Transactional(readOnly = true)
	public List<FoodResponse> getRecentFoods() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<Food> recentFoods = mealItemRepository.findRecentFoods(currentUser.getId(), PageRequest.of(0, 20));

		java.util.Map<Long, UserFoodOverride> overrides = loadOverrides(currentUser.getId(), recentFoods);

		List<FoodResponse> results = new ArrayList<>();
		for (Food food : recentFoods) {
			UserFoodOverride override = overrides.get(food.getId());
			if (override != null) {
				results.add(convertToResponse(food, override));
				boolean isBrandVerified = food.getBrand() != null && !food.getBrand().isEmpty();
				results.add(nutritionMapper.toFoodResponse(food, false, isBrandVerified));
			}
			else {
				results.add(convertToResponse(food, (UserFoodOverride) null));
			}
		}
		return results;
	}

	@Transactional(readOnly = true)
	public List<MealHistoryResponse> getRecentGroupedFoods() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<Object[]> queryResults = mealIngredientRepository.findRecentFoodsWithMealTypeByUserId(currentUser.getId(),
				PageRequest.of(0, 50));

		// Besinler ve kullanıcı ezmeleri TEK sorguda toplanır. Daha önce satır başına
		// findById, üstüne her besin için convertToResponse içindeki ezme sorgusu
		// çalışıyordu: 50 satırlık sonuç ~100 sorgu üretiyordu.
		List<Long> foodIds = queryResults.stream().map(row -> (Long) row[0]).distinct().toList();
		java.util.Map<Long, Food> foodsById = foodIds.isEmpty() ? java.util.Map.of()
				: foodRepository.findAllById(foodIds)
					.stream()
					.collect(Collectors.toMap(Food::getId, food -> food, (first, second) -> first));
		java.util.Map<Long, UserFoodOverride> overrides = loadOverrides(currentUser.getId(),
				List.copyOf(foodsById.values()));

		java.util.Map<MealType, List<FoodResponse>> grouped = new java.util.LinkedHashMap<>();
		for (Object[] row : queryResults) {
			Food food = foodsById.get((Long) row[0]);
			if (food == null) {
				continue;
			}
			MealType mType = (MealType) row[1];
			grouped.computeIfAbsent(mType, k -> new java.util.ArrayList<>())
				.add(convertToResponse(food, overrides.get(food.getId())));
		}

		return grouped.entrySet()
			.stream()
			.map(e -> new MealHistoryResponse(e.getKey(), e.getValue()))
			.collect(Collectors.toList());
	}

	@Transactional(readOnly = true)
	public List<FoodResponse> getOverriddenFoods() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<UserFoodOverride> overrides = overrideRepository.findAllByUserId(currentUser.getId());

		// Ezme kayıtları zaten elde; tekrar sorgulamaya gerek yok.
		return overrides.stream().map(ov -> convertToResponse(ov.getFood(), ov)).collect(Collectors.toList());
	}

	@Transactional(readOnly = true)
	public List<FoodResponse> getMyCustomFoods() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<Food> myFoods = foodRepository.findByCreatorIdOrderByCreatedAtDesc(currentUser.getId());
		java.util.Map<Long, UserFoodOverride> overrides = loadOverrides(currentUser.getId(), myFoods);
		return myFoods.stream().map(f -> convertToResponse(f, overrides.get(f.getId()))).collect(Collectors.toList());
	}

	@Transactional(readOnly = true)
	public FoodResponse getFoodDetails(Long foodId, boolean ignoreOverride) {
		AppUser currentUser = userContextService.getCurrentUser();
		Food food = foodRepository.findById(foodId).orElseThrow(() -> new NotFoundException("Besin bulunamadı."));

		if (!food.isGlobal() && !resolveVisibleCreatorIds(currentUser).contains(food.getCreatorId())) {
			throw new NotFoundException("Besin bulunamadı.");
		}

		if (ignoreOverride) {
			boolean isBrandVerified = food.getBrand() != null && !food.getBrand().isEmpty();
			return new FoodResponse(food.getId(), food.getName(), food.getBrand(), food.getCategory(),
					food.getDefaultUnit(), food.getDefaultAmount(), food.getCalories(), food.getProtein(),
					food.getCarbs(), food.getFat(), food.getSugar(), food.getFiber(), food.getSodium(),
					food.getCholesterol(), food.getPotassium(), food.getSatFat(), food.getTransFat(), food.getMonoFat(),
					food.getPolyFat(), false, // isOverridden = false (Explicit)
					isBrandVerified, food.getBarcode());
		}

		return convertToResponse(food, currentUser.getId());
	}

	/**
	 * Barkod ile besin getirir (Sadece yerel veritabanından).
	 */
	@Transactional(readOnly = true)
	public FoodResponse getFoodByBarcode(String barcode) {
		AppUser currentUser = userContextService.getCurrentUser();
		Food food = foodRepository.findByBarcode(barcode)
			.orElseThrow(() -> new NotFoundException("Besin bulunamadı: " + barcode));

		if (!food.isGlobal() && !resolveVisibleCreatorIds(currentUser).contains(food.getCreatorId())) {
			throw new NotFoundException("Besin bulunamadı: " + barcode);
		}

		return convertToResponse(food, currentUser.getId());
	}

	@Transactional
	public FoodResponse createCustomFood(FoodCreateRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();
		long count = foodRepository.countByCreatorId(currentUser.getId());
		if (count >= 200) {
			throw new BadRequestException("En fazla 200 özel besin ekleyebilirsiniz. "
					+ "Yeni eklemek için önce arama yapıp mevcut besinleri kullanın veya eskilerini temizleyin.");
		}

		Food food = new Food();
		food.setName(request.name());
		food.setBrand(request.brand());
		food.setCategory(request.category());
		food.setDefaultUnit(request.defaultUnit());
		food.setDefaultAmount(request.defaultAmount());
		food.setCalories(request.calories());
		food.setProtein(request.protein());
		food.setCarbs(request.carbs());
		food.setFat(request.fat());
		food.setSugar(request.sugar());
		food.setFiber(request.fiber());
		food.setSodium(request.sodium());
		food.setCholesterol(request.cholesterol());
		food.setPotassium(request.potassium());
		food.setSatFat(request.satFat());
		food.setTransFat(request.transFat());
		food.setMonoFat(request.monoFat());
		food.setPolyFat(request.polyFat());
		food.setCreatorId(currentUser.getId());
		food.setGlobal(false);
		food.onPersist(clock.instant());

		Food saved = foodRepository.save(food);
		return convertToResponse(saved, currentUser.getId());
	}

	@Transactional
	public FoodResponse overrideFood(Long foodId, FoodOverrideRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();
		Food food = foodRepository.findById(foodId).orElseThrow(() -> new NotFoundException("Besin bulunamadı."));

		saveOverride(currentUser, food, request);
		return convertToResponse(food, currentUser.getId());
	}

	@Transactional
	public FoodResponse overrideFoodByBarcode(String barcode, FoodOverrideRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();
		Food food = foodRepository.findByBarcode(barcode).orElseThrow(() -> new NotFoundException("Besin bulunamadı."));

		saveOverride(currentUser, food, request);
		return convertToResponse(food, currentUser.getId());
	}

	@Transactional
	public void deleteOverride(Long foodId) {
		AppUser currentUser = userContextService.getCurrentUser();
		overrideRepository.findByUserIdAndFoodId(currentUser.getId(), foodId).ifPresent(overrideRepository::delete);
	}

	private void saveOverride(AppUser user, Food food, FoodOverrideRequest request) {
		UserFoodOverride override = overrideRepository.findByUserIdAndFoodId(user.getId(), food.getId())
			.orElseGet(() -> {
				UserFoodOverride newOverride = new UserFoodOverride(user, food);
				newOverride.setCreatedAt(LocalDateTime.now(clock)); // Set creation time
																	// for new overrides
				return newOverride;
			});

		override.setCalories(request.calories());
		override.setProtein(request.protein());
		override.setCarbs(request.carbs());
		override.setFat(request.fat());
		override.setSugar(request.sugar());
		override.setFiber(request.fiber());
		override.setSodium(request.sodium());
		override.setCholesterol(request.cholesterol());
		override.setPotassium(request.potassium());
		override.setSatFat(request.satFat());
		override.setTransFat(request.transFat());
		override.setMonoFat(request.monoFat());
		override.setPolyFat(request.polyFat());
		override.setUpdatedAt(LocalDateTime.now(clock));

		overrideRepository.save(override);
	}

	/**
	 * Tek bir besin için kullanılır; ezme kaydı burada sorgulanır.
	 * <p>
	 * Liste üreten metotlar bunu <b>kullanmaz</b>: onlar ezmeleri {@link #loadOverrides}
	 * ile tek sorguda toplayıp {@link #convertToResponse(Food, UserFoodOverride)}
	 * çağırır.
	 * </p>
	 */
	private FoodResponse convertToResponse(Food food, Long userId) {
		return convertToResponse(food, overrideRepository.findByUserIdAndFoodId(userId, food.getId()).orElse(null));
	}

	/**
	 * Verilen besinler için kullanıcının ezme kayıtlarını tek sorguda getirir.
	 * <p>
	 * Ezme kaydı besin başına sorgulanırsa arama sonuçlarının maliyeti sonuç sayısıyla
	 * birlikte büyür.
	 * </p>
	 */
	private java.util.Map<Long, UserFoodOverride> loadOverrides(Long userId, List<Food> foods) {
		if (foods.isEmpty()) {
			return java.util.Map.of();
		}
		List<Long> foodIds = foods.stream().map(Food::getId).toList();
		return overrideRepository.findByUserIdAndFoodIdIn(userId, foodIds)
			.stream()
			.collect(Collectors.toMap(ov -> ov.getFood().getId(), ov -> ov, (first, second) -> first));
	}

	private FoodResponse convertToResponse(Food food, UserFoodOverride override) {
		boolean isBrandVerified = food.getBrand() != null && !food.getBrand().isEmpty();

		if (override != null) {
			UserFoodOverride ov = override;
			return new FoodResponse(food.getId(), food.getName(), food.getBrand(), food.getCategory(),
					food.getDefaultUnit(), food.getDefaultAmount(),
					ov.getCalories() != null ? ov.getCalories() : food.getCalories(),
					ov.getProtein() != null ? ov.getProtein() : food.getProtein(),
					ov.getCarbs() != null ? ov.getCarbs() : food.getCarbs(),
					ov.getFat() != null ? ov.getFat() : food.getFat(),
					ov.getSugar() != null ? ov.getSugar() : food.getSugar(),
					ov.getFiber() != null ? ov.getFiber() : food.getFiber(),
					ov.getSodium() != null ? ov.getSodium() : food.getSodium(),
					ov.getCholesterol() != null ? ov.getCholesterol() : food.getCholesterol(),
					ov.getPotassium() != null ? ov.getPotassium() : food.getPotassium(),
					ov.getSatFat() != null ? ov.getSatFat() : food.getSatFat(),
					ov.getTransFat() != null ? ov.getTransFat() : food.getTransFat(),
					ov.getMonoFat() != null ? ov.getMonoFat() : food.getMonoFat(),
					ov.getPolyFat() != null ? ov.getPolyFat() : food.getPolyFat(), true, isBrandVerified,
					food.getBarcode());
		}

		return nutritionMapper.toFoodResponse(food, false, isBrandVerified);
	}

}
