package com.gym.v2.nutrition.service;

import com.gym.v2.nutrition.dto.NutrientSummary;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.MealItem;
import com.gym.v2.nutrition.entity.RecipeIngredient;
import com.gym.v2.nutrition.entity.UserFoodOverride;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * {@code NutrientCalculator} birim testleri.
 * <p>
 * Bu sınıf kullanıcıya gösterilen kalori ve makro değerlerini üretir; buradaki bir hata
 * sessizce yanlış beslenme hedefine yol açar ve kimse fark etmez. Ölçülen kapsamı %1,3
 * olduğu için öncelikli alındı.
 * </p>
 * <p>
 * Testlerde her besin alanına <b>farklı</b> değerler verilir. Böylece alanların birbirine
 * karışması (örn. sodyum ile potasyumun yer değiştirmesi) yakalanır; hepsi aynı değer
 * olsaydı böyle bir hata görünmezdi.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class NutrientCalculatorTest {

	@Mock
	private UserFoodOverrideRepository overrideRepository;

	private NutrientCalculator calculator;

	private static final Long USER_ID = 1L;

	@BeforeEach
	void setUp() {
		calculator = new NutrientCalculator(overrideRepository);
	}

	/** Her alanı ayırt edilebilir bir değere sahip, 100 g bazlı referans besin. */
	private Food referenceFood() {
		Food food = new Food();
		food.setId(10L);
		food.setName("Test Besin");
		food.setDefaultAmount(new BigDecimal("100"));
		food.setProtein(new BigDecimal("10"));
		food.setCarbs(new BigDecimal("20"));
		food.setFat(new BigDecimal("30"));
		food.setCalories(new BigDecimal("40"));
		food.setSugar(new BigDecimal("50"));
		food.setFiber(new BigDecimal("60"));
		food.setSodium(new BigDecimal("70"));
		food.setPotassium(new BigDecimal("80"));
		food.setCholesterol(new BigDecimal("90"));
		return food;
	}

	// ---------------------------------------------------------------------------
	// calculateFoodNutrientRatio — porsiyon oranı
	// ---------------------------------------------------------------------------

	@Test
	void calculateFoodNutrientRatio_amountAboveBaseAmount_returnsProportionalRatio() {
		Food food = referenceFood();

		BigDecimal ratio = calculator.calculateFoodNutrientRatio(food, new BigDecimal("150"));

		assertThat(ratio).isEqualByComparingTo(new BigDecimal("1.5"));
	}

	@Test
	void calculateFoodNutrientRatio_nullDefaultAmount_fallsBackToHundredGramBase() {
		Food food = referenceFood();
		food.setDefaultAmount(null);

		BigDecimal ratio = calculator.calculateFoodNutrientRatio(food, new BigDecimal("50"));

		assertThat(ratio).isEqualByComparingTo(new BigDecimal("0.5"));
	}

	@Test
	void calculateFoodNutrientRatio_zeroDefaultAmount_fallsBackInsteadOfDividingByZero() {
		Food food = referenceFood();
		food.setDefaultAmount(BigDecimal.ZERO);

		BigDecimal ratio = calculator.calculateFoodNutrientRatio(food, new BigDecimal("200"));

		assertThat(ratio).isEqualByComparingTo(new BigDecimal("2"));
	}

	@Test
	void calculateFoodNutrientRatio_portionBasedFood_usesItsOwnBaseAmount() {
		// 1 adet = 60 g olan bir besin: 30 g yenirse oran 0.5 olmalı.
		Food food = referenceFood();
		food.setDefaultAmount(new BigDecimal("60"));

		BigDecimal ratio = calculator.calculateFoodNutrientRatio(food, new BigDecimal("30"));

		assertThat(ratio).isEqualByComparingTo(new BigDecimal("0.5"));
	}

	// ---------------------------------------------------------------------------
	// multiplySafely — null güvenliği ve yuvarlama
	// ---------------------------------------------------------------------------

	@Test
	void multiplySafely_nullValueOrMultiplier_returnsZeroInsteadOfThrowing() {
		assertThat(calculator.multiplySafely(null, BigDecimal.ONE)).isEqualByComparingTo(BigDecimal.ZERO);
		assertThat(calculator.multiplySafely(BigDecimal.ONE, null)).isEqualByComparingTo(BigDecimal.ZERO);
	}

	@Test
	void multiplySafely_roundsToTwoDecimalsHalfUp() {
		BigDecimal result = calculator.multiplySafely(new BigDecimal("10"), new BigDecimal("0.3333"));

		// 3.333 → 3.33
		assertThat(result).isEqualByComparingTo(new BigDecimal("3.33"));
		assertThat(result.scale()).isEqualTo(2);
	}

	// ---------------------------------------------------------------------------
	// getOverriddenFoodNutrients — kullanıcı düzeltmeleri
	// ---------------------------------------------------------------------------

	@Test
	void getOverriddenFoodNutrients_noOverride_returnsFoodValuesInCorrectFields() {
		Food food = referenceFood();
		when(overrideRepository.findByUserIdAndFoodId(USER_ID, 10L)).thenReturn(Optional.empty());

		NutrientSummary summary = calculator.getOverriddenFoodNutrients(food, USER_ID);

		// Alanların karışmadığını her biri için ayrı ayrı doğrula.
		assertThat(summary.protein()).isEqualByComparingTo("10");
		assertThat(summary.carbs()).isEqualByComparingTo("20");
		assertThat(summary.fat()).isEqualByComparingTo("30");
		assertThat(summary.calories()).isEqualByComparingTo("40");
		assertThat(summary.sugar()).isEqualByComparingTo("50");
		assertThat(summary.fiber()).isEqualByComparingTo("60");
		assertThat(summary.sodium()).isEqualByComparingTo("70");
		assertThat(summary.potassium()).isEqualByComparingTo("80");
		assertThat(summary.cholesterol()).isEqualByComparingTo("90");
	}

	@Test
	void getOverriddenFoodNutrients_partialOverride_replacesOnlyProvidedFields() {
		Food food = referenceFood();
		UserFoodOverride override = new UserFoodOverride();
		override.setCalories(new BigDecimal("999"));
		override.setProtein(new BigDecimal("111"));
		// Diğer alanlar null bırakıldı: besinin kendi değerleri korunmalı.
		when(overrideRepository.findByUserIdAndFoodId(USER_ID, 10L)).thenReturn(Optional.of(override));

		NutrientSummary summary = calculator.getOverriddenFoodNutrients(food, USER_ID);

		assertThat(summary.calories()).isEqualByComparingTo("999");
		assertThat(summary.protein()).isEqualByComparingTo("111");
		assertThat(summary.carbs()).isEqualByComparingTo("20");
		assertThat(summary.fat()).isEqualByComparingTo("30");
		assertThat(summary.potassium()).isEqualByComparingTo("80");
	}

	// ---------------------------------------------------------------------------
	// calculateMealItemNutrients — öğün kalemi hesabı
	// ---------------------------------------------------------------------------

	@Test
	void calculateMealItemNutrients_halfPortion_scalesEveryNutrientByRatio() {
		Food food = referenceFood();
		MealItem item = new MealItem();
		item.setAmount(new BigDecimal("50"));
		when(overrideRepository.findByUserIdAndFoodId(USER_ID, 10L)).thenReturn(Optional.empty());

		calculator.calculateMealItemNutrients(item, food, USER_ID);

		assertThat(item.getProtein()).isEqualByComparingTo("5");
		assertThat(item.getCarbs()).isEqualByComparingTo("10");
		assertThat(item.getFat()).isEqualByComparingTo("15");
		assertThat(item.getCalories()).isEqualByComparingTo("20");
		assertThat(item.getSugar()).isEqualByComparingTo("25");
		assertThat(item.getFiber()).isEqualByComparingTo("30");
		assertThat(item.getSodium()).isEqualByComparingTo("35");
		assertThat(item.getPotassium()).isEqualByComparingTo("40");
		assertThat(item.getCholesterol()).isEqualByComparingTo("45");
	}

	@Test
	void calculateMealItemNutrients_nullAmount_yieldsZeroInsteadOfThrowing() {
		Food food = referenceFood();
		MealItem item = new MealItem();
		item.setAmount(null);
		when(overrideRepository.findByUserIdAndFoodId(USER_ID, 10L)).thenReturn(Optional.empty());

		calculator.calculateMealItemNutrients(item, food, USER_ID);

		assertThat(item.getCalories()).isEqualByComparingTo(BigDecimal.ZERO);
		assertThat(item.getProtein()).isEqualByComparingTo(BigDecimal.ZERO);
	}

	// ---------------------------------------------------------------------------
	// calculateRecipeTotals — tarif toplamı
	// ---------------------------------------------------------------------------

	private RecipeIngredient ingredientOf(Food food, String amount) {
		RecipeIngredient ing = new RecipeIngredient();
		ing.setFood(food);
		ing.setAmount(new BigDecimal(amount));
		return ing;
	}

	@Test
	void calculateRecipeTotals_multipleIngredients_sumsEachScaledByItsOwnAmount() {
		Food food = referenceFood();
		lenient().when(overrideRepository.findByUserIdAndFoodId(any(), any())).thenReturn(Optional.empty());

		// 100 g (oran 1) + 50 g (oran 0.5) = toplam 1.5 kat
		NutrientSummary totals = calculator
			.calculateRecipeTotals(List.of(ingredientOf(food, "100"), ingredientOf(food, "50")), USER_ID);

		assertThat(totals.protein()).isEqualByComparingTo("15");
		assertThat(totals.carbs()).isEqualByComparingTo("30");
		assertThat(totals.calories()).isEqualByComparingTo("60");
		assertThat(totals.cholesterol()).isEqualByComparingTo("135");
	}

	@Test
	void calculateRecipeTotals_emptyIngredientList_returnsAllZeros() {
		NutrientSummary totals = calculator.calculateRecipeTotals(List.of(), USER_ID);

		assertThat(totals.protein()).isEqualByComparingTo(BigDecimal.ZERO);
		assertThat(totals.calories()).isEqualByComparingTo(BigDecimal.ZERO);
	}

	// ---------------------------------------------------------------------------
	// calculateMealEntryTotals — günlük öğün toplamı
	// ---------------------------------------------------------------------------

	private MealItem itemWith(String protein, String carbs, String fat, String calories) {
		MealItem item = new MealItem();
		item.setProtein(new BigDecimal(protein));
		item.setCarbs(new BigDecimal(carbs));
		item.setFat(new BigDecimal(fat));
		item.setCalories(new BigDecimal(calories));
		return item;
	}

	@Test
	void calculateMealEntryTotals_multipleItems_sumsAndRoundsToTwoDecimals() {
		MealEntry entry = new MealEntry();
		entry.setItems(List.of(itemWith("10", "20", "30", "40"), itemWith("1.5", "2.5", "3.5", "4.5")));

		calculator.calculateMealEntryTotals(entry);

		assertThat(entry.getProtein()).isEqualByComparingTo("11.5");
		assertThat(entry.getCarbs()).isEqualByComparingTo("22.5");
		assertThat(entry.getFat()).isEqualByComparingTo("33.5");
		assertThat(entry.getCalories()).isEqualByComparingTo("44.5");
		assertThat(entry.getCalories().scale()).isEqualTo(2);
	}

	@Test
	void calculateMealEntryTotals_itemsWithNullNutrients_skipsThemInsteadOfThrowing() {
		MealEntry entry = new MealEntry();
		MealItem incomplete = new MealItem();
		incomplete.setCalories(new BigDecimal("100"));
		// protein/carbs/fat null bırakıldı — barkodsuz/eksik verili besinler böyle gelir.
		entry.setItems(List.of(incomplete));

		calculator.calculateMealEntryTotals(entry);

		assertThat(entry.getCalories()).isEqualByComparingTo("100");
		assertThat(entry.getProtein()).isEqualByComparingTo(BigDecimal.ZERO);
	}

}
