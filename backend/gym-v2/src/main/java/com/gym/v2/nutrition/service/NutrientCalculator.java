package com.gym.v2.nutrition.service;

import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.Recipe;
import com.gym.v2.nutrition.entity.MealItem;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.RecipeIngredient;
import com.gym.v2.nutrition.entity.MealIngredient;
import com.gym.v2.nutrition.entity.MealTemplateIngredient;
import com.gym.v2.nutrition.dto.RecipeResponse;
import com.gym.v2.nutrition.dto.RecipeIngredientResponse;
import com.gym.v2.nutrition.dto.NutrientSummary;
import com.gym.v2.nutrition.dto.MealIngredientResponse;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import org.mapstruct.Context;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

/**
 * Beslenme modülü için merkezi hesaplama motoru. Gram (Yemek) ve Porsiyon (Tarif)
 * mantığına göre makro/mikro hesaplar.
 *
 * OPTIMIZATION: MapStruct entegrasyonu için "toIngredientResponse" metotları eklendi.
 */
@Component
public class NutrientCalculator {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(NutrientCalculator.class);

	public static final BigDecimal DEFAULT_BASE_AMOUNT = new BigDecimal("100");

	private final UserFoodOverrideRepository overrideRepository;

	public NutrientCalculator(UserFoodOverrideRepository overrideRepository) {
		this.overrideRepository = overrideRepository;
	}

	/**
	 * MapStruct için merkezi Ingredient mapping metodu (MealIngredient).
	 */
	public MealIngredientResponse toIngredientResponse(MealIngredient ingredient, @Context Long userId) {
		if (ingredient == null) {
			return null;
		}

		if (ingredient.getFood() != null) {
			return calculateIngredientResponse(ingredient.getId(), ingredient.getFood(), ingredient.getAmount(),
					ingredient.isIgnoreOverride(), userId);
		}
		else if (ingredient.getRecipe() != null) {
			return calculateRecipeIngredientResponse(ingredient.getId(), ingredient.getRecipe(), ingredient.getAmount(),
					userId);
		}
		return null;
	}

	/**
	 * MapStruct için merkezi Ingredient mapping metodu (MealTemplateIngredient).
	 */
	public MealIngredientResponse toIngredientResponse(MealTemplateIngredient ingredient, @Context Long userId) {
		if (ingredient == null) {
			return null;
		}

		if (ingredient.getFood() != null) {
			return calculateIngredientResponse(ingredient.getId(), ingredient.getFood(), ingredient.getAmount(),
					ingredient.isIgnoreOverride(), userId);
		}
		else if (ingredient.getRecipe() != null) {
			return calculateRecipeIngredientResponse(ingredient.getId(), ingredient.getRecipe(), ingredient.getAmount(),
					userId);
		}
		return null;
	}

	/**
	 * Bir liste dolusu IngredientResponse'un toplam besin değerlerini hesaplar.
	 */
	public NutrientSummary calculateTotal(List<MealIngredientResponse> ingredients) {
		BigDecimal prot = BigDecimal.ZERO;
		BigDecimal carb = BigDecimal.ZERO;
		BigDecimal fat = BigDecimal.ZERO;
		BigDecimal cal = BigDecimal.ZERO;
		BigDecimal sug = BigDecimal.ZERO;
		BigDecimal fib = BigDecimal.ZERO;
		BigDecimal sod = BigDecimal.ZERO;
		BigDecimal pot = BigDecimal.ZERO;
		BigDecimal chol = BigDecimal.ZERO;

		for (var ing : ingredients) {
			prot = addValue(prot, ing.protein());
			carb = addValue(carb, ing.carbs());
			fat = addValue(fat, ing.fat());
			cal = addValue(cal, ing.calories());
			sug = addValue(sug, ing.sugar());
			fib = addValue(fib, ing.fiber());
			sod = addValue(sod, ing.sodium());
			pot = addValue(pot, ing.potassium());
			chol = addValue(chol, ing.cholesterol());
		}
		return new NutrientSummary(prot, carb, fat, cal, sug, fib, sod, pot, chol);
	}

	private MealIngredientResponse calculateIngredientResponse(Long id, Food food, BigDecimal amount,
			boolean ignoreOverride, Long userId) {
		BigDecimal ratio = calculateFoodNutrientRatio(food, amount);

		if (ignoreOverride) {
			return new MealIngredientResponse(id, food.getId(), food.getName(), food.getBrand(), amount,
					food.getDefaultAmount(), multiplySafely(food.getProtein(), ratio),
					multiplySafely(food.getCarbs(), ratio), multiplySafely(food.getFat(), ratio),
					multiplySafely(food.getCalories(), ratio), food.getBarcode() != null, false,
					multiplySafely(food.getSugar(), ratio), multiplySafely(food.getFiber(), ratio),
					multiplySafely(food.getSodium(), ratio), multiplySafely(food.getPotassium(), ratio),
					multiplySafely(food.getCholesterol(), ratio), null, false, !food.isGlobal());
		}

		NutrientSummary nuts = getOverriddenFoodNutrients(food, userId);
		return new MealIngredientResponse(id, food.getId(), food.getName(), food.getBrand(), amount,
				food.getDefaultAmount(), multiplySafely(nuts.protein(), ratio), multiplySafely(nuts.carbs(), ratio),
				multiplySafely(nuts.fat(), ratio), multiplySafely(nuts.calories(), ratio), food.getBarcode() != null,
				true, multiplySafely(nuts.sugar(), ratio), multiplySafely(nuts.fiber(), ratio),
				multiplySafely(nuts.sodium(), ratio), multiplySafely(nuts.potassium(), ratio),
				multiplySafely(nuts.cholesterol(), ratio), null, isFoodOverridden(food.getId(), userId),
				!food.isGlobal());
	}

	private MealIngredientResponse calculateRecipeIngredientResponse(Long id, Recipe recipe, BigDecimal amount,
			Long userId) {
		NutrientSummary summary = calculateRecipeTotals(recipe.getIngredients(), userId);
		return new MealIngredientResponse(id, null, recipe.getName(), "Tarif", amount, BigDecimal.ONE,
				multiplySafely(summary.protein(), amount), multiplySafely(summary.carbs(), amount),
				multiplySafely(summary.fat(), amount), multiplySafely(summary.calories(), amount), false, true,
				multiplySafely(summary.sugar(), amount), multiplySafely(summary.fiber(), amount),
				multiplySafely(summary.sodium(), amount), multiplySafely(summary.potassium(), amount),
				multiplySafely(summary.cholesterol(), amount), recipe.getId(), false, false);
	}

	/**
	 * MealItem için besin değerlerini hesaplar ve atar (Yiyecek - Gram Bazlı).
	 */
	public void calculateMealItemNutrients(MealItem item, Food food, Long userId) {
		BigDecimal amount = item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO;
		NutrientSummary nuts = getOverriddenFoodNutrients(food, userId);

		BigDecimal defaultAmt = (food.getDefaultAmount() == null
				|| food.getDefaultAmount().compareTo(BigDecimal.ZERO) <= 0) ? DEFAULT_BASE_AMOUNT
						: food.getDefaultAmount();

		BigDecimal ratio = amount.divide(defaultAmt, 4, RoundingMode.HALF_UP);

		item.setCalories(multiplySafely(nuts.calories(), ratio));
		item.setProtein(multiplySafely(nuts.protein(), ratio));
		item.setCarbs(multiplySafely(nuts.carbs(), ratio));
		item.setFat(multiplySafely(nuts.fat(), ratio));
		item.setSugar(multiplySafely(nuts.sugar(), ratio));
		item.setFiber(multiplySafely(nuts.fiber(), ratio));
		item.setSodium(multiplySafely(nuts.sodium(), ratio));
		item.setCholesterol(multiplySafely(nuts.cholesterol(), ratio));
		item.setPotassium(multiplySafely(nuts.potassium(), ratio));
	}

	/**
	 * MealItem için besin değerlerini hesaplar ve atar (Tarif - Porsiyon Bazlı).
	 */
	public void calculateMealItemNutrients(MealItem item, Recipe recipe, Long userId) {
		BigDecimal portions = item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO;
		NutrientSummary summary = calculateRecipeTotals(recipe.getIngredients(), userId);

		item.setCalories(multiplySafely(summary.calories(), portions));
		item.setProtein(multiplySafely(summary.protein(), portions));
		item.setCarbs(multiplySafely(summary.carbs(), portions));
		item.setFat(multiplySafely(summary.fat(), portions));
		item.setSugar(multiplySafely(summary.sugar(), portions));
		item.setFiber(multiplySafely(summary.fiber(), portions));
		item.setSodium(multiplySafely(summary.sodium(), portions));
		item.setPotassium(multiplySafely(summary.potassium(), portions));
		item.setCholesterol(multiplySafely(summary.cholesterol(), portions));
	}

	public NutrientSummary calculateRecipeTotals(List<RecipeIngredient> ingredients, Long userId) {
		BigDecimal prot = BigDecimal.ZERO;
		BigDecimal carb = BigDecimal.ZERO;
		BigDecimal fat = BigDecimal.ZERO;
		BigDecimal cal = BigDecimal.ZERO;
		BigDecimal sug = BigDecimal.ZERO;
		BigDecimal fib = BigDecimal.ZERO;
		BigDecimal sod = BigDecimal.ZERO;
		BigDecimal pot = BigDecimal.ZERO;
		BigDecimal chol = BigDecimal.ZERO;

		for (var ing : ingredients) {
			BigDecimal foodNutrientRatio = calculateFoodNutrientRatio(ing.getFood(), ing.getAmount());
			NutrientSummary nutrients = getOverriddenFoodNutrients(ing.getFood(), userId);

			prot = prot.add(multiplySafely(nutrients.protein(), foodNutrientRatio));
			carb = carb.add(multiplySafely(nutrients.carbs(), foodNutrientRatio));
			fat = fat.add(multiplySafely(nutrients.fat(), foodNutrientRatio));
			cal = cal.add(multiplySafely(nutrients.calories(), foodNutrientRatio));
			sug = sug.add(multiplySafely(nutrients.sugar(), foodNutrientRatio));
			fib = fib.add(multiplySafely(nutrients.fiber(), foodNutrientRatio));
			sod = sod.add(multiplySafely(nutrients.sodium(), foodNutrientRatio));
			pot = pot.add(multiplySafely(nutrients.potassium(), foodNutrientRatio));
			chol = chol.add(multiplySafely(nutrients.cholesterol(), foodNutrientRatio));
		}
		return new NutrientSummary(prot, carb, fat, cal, sug, fib, sod, pot, chol);
	}

	public boolean isFoodOverridden(Long foodId, Long userId) {
		if (foodId == null || userId == null) {
			return false;
		}
		return overrideRepository.findByUserIdAndFoodId(userId, foodId).isPresent();
	}

	public BigDecimal calculateFoodNutrientRatio(Food food, BigDecimal amount) {
		BigDecimal defAmt = (food.getDefaultAmount() == null || food.getDefaultAmount().compareTo(BigDecimal.ZERO) <= 0)
				? DEFAULT_BASE_AMOUNT : food.getDefaultAmount();
		return amount.divide(defAmt, 4, RoundingMode.HALF_UP);
	}

	public NutrientSummary getOverriddenFoodNutrients(Food food, Long userId) {
		BigDecimal cal = food.getCalories();
		BigDecimal prot = food.getProtein();
		BigDecimal carb = food.getCarbs();
		BigDecimal fat = food.getFat();
		BigDecimal sug = food.getSugar();
		BigDecimal fib = food.getFiber();
		BigDecimal sod = food.getSodium();
		BigDecimal chol = food.getCholesterol();
		BigDecimal pot = food.getPotassium();

		var overrideOpt = overrideRepository.findByUserIdAndFoodId(userId, food.getId());
		if (overrideOpt.isPresent()) {
			var ov = overrideOpt.get();
			if (ov.getCalories() != null) {
				cal = ov.getCalories();
			}
			if (ov.getProtein() != null) {
				prot = ov.getProtein();
			}
			if (ov.getCarbs() != null) {
				carb = ov.getCarbs();
			}
			if (ov.getFat() != null) {
				fat = ov.getFat();
			}
			if (ov.getSugar() != null) {
				sug = ov.getSugar();
			}
			if (ov.getFiber() != null) {
				fib = ov.getFiber();
			}
			if (ov.getSodium() != null) {
				sod = ov.getSodium();
			}
			if (ov.getCholesterol() != null) {
				chol = ov.getCholesterol();
			}
			if (ov.getPotassium() != null) {
				pot = ov.getPotassium();
			}
		}
		return new NutrientSummary(prot, carb, fat, cal, sug, fib, sod, pot, chol);
	}

	public RecipeResponse calculateRecipeResponse(Recipe recipe, Long userId) {
		NutrientSummary totals = calculateRecipeTotals(recipe.getIngredients(), userId);
		return new RecipeResponse(recipe.getId(), recipe.getName(), recipe.getDescription(), recipe.getInstructions(),
				recipe.getCategory(), recipe.getImageUrl(), recipe.getCreatedAt(),
				recipe.getIngredients().stream().map(ing -> {
					NutrientSummary nuts = getOverriddenFoodNutrients(ing.getFood(), userId);
					BigDecimal ratio = calculateFoodNutrientRatio(ing.getFood(), ing.getAmount());
					return new RecipeIngredientResponse(ing.getId(), ing.getFood().getId(), ing.getFood().getName(),
							ing.getFood().getBrand(), ing.getAmount(), multiplySafely(nuts.protein(), ratio),
							multiplySafely(nuts.carbs(), ratio), multiplySafely(nuts.fat(), ratio),
							multiplySafely(nuts.calories(), ratio), ing.getFood().getDefaultUnit(),
							isFoodOverridden(ing.getFood().getId(), userId));
				}).toList(), totals.calories(), totals.protein(), totals.carbs(), totals.fat());
	}

	public void calculateMealEntryTotals(MealEntry entry) {
		BigDecimal prot = BigDecimal.ZERO;
		BigDecimal carb = BigDecimal.ZERO;
		BigDecimal fat = BigDecimal.ZERO;
		BigDecimal cal = BigDecimal.ZERO;
		BigDecimal sug = BigDecimal.ZERO;
		BigDecimal fib = BigDecimal.ZERO;
		BigDecimal sod = BigDecimal.ZERO;
		BigDecimal chol = BigDecimal.ZERO;
		BigDecimal pot = BigDecimal.ZERO;
		BigDecimal sat = BigDecimal.ZERO;
		BigDecimal trans = BigDecimal.ZERO;
		BigDecimal mono = BigDecimal.ZERO;
		BigDecimal poly = BigDecimal.ZERO;

		for (var item : entry.getItems()) {
			prot = addValue(prot, item.getProtein());
			carb = addValue(carb, item.getCarbs());
			fat = addValue(fat, item.getFat());
			cal = addValue(cal, item.getCalories());
			sug = addValue(sug, item.getSugar());
			fib = addValue(fib, item.getFiber());
			sod = addValue(sod, item.getSodium());
			chol = addValue(chol, item.getCholesterol());
			pot = addValue(pot, item.getPotassium());
			sat = addValue(sat, item.getSatFat());
			trans = addValue(trans, item.getTransFat());
			mono = addValue(mono, item.getMonoFat());
			poly = addValue(poly, item.getPolyFat());
		}

		entry.setProtein(prot.setScale(2, RoundingMode.HALF_UP));
		entry.setCarbs(carb.setScale(2, RoundingMode.HALF_UP));
		entry.setFat(fat.setScale(2, RoundingMode.HALF_UP));
		entry.setCalories(cal.setScale(2, RoundingMode.HALF_UP));
		entry.setSugar(sug.setScale(2, RoundingMode.HALF_UP));
		entry.setFiber(fib.setScale(2, RoundingMode.HALF_UP));
		entry.setSodium(sod.setScale(2, RoundingMode.HALF_UP));
		entry.setCholesterol(chol.setScale(2, RoundingMode.HALF_UP));
		entry.setPotassium(pot.setScale(2, RoundingMode.HALF_UP));
		entry.setSatFat(sat.setScale(2, RoundingMode.HALF_UP));
		entry.setTransFat(trans.setScale(2, RoundingMode.HALF_UP));
		entry.setMonoFat(mono.setScale(2, RoundingMode.HALF_UP));
		entry.setPolyFat(poly.setScale(2, RoundingMode.HALF_UP));
	}

	private BigDecimal addValue(BigDecimal current, BigDecimal toAdd) {
		if (toAdd == null) {
			return current;
		}
		return current.add(toAdd);
	}

	public BigDecimal multiplySafely(BigDecimal value, BigDecimal multiplier) {
		if (value == null || multiplier == null) {
			return BigDecimal.ZERO;
		}
		return value.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
	}

}
