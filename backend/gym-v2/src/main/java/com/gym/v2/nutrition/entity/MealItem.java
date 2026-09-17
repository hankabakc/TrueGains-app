package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.AssertTrue;
import java.math.BigDecimal;

/**
 * Öğün Girdisi İçeriği (MealItem) Kullanıcının MealEntry (Öğün) içerisinde hangi food'dan
 * (Besin) kaç gram yediğini tutar.
 */
@Entity
@Table(name = "meal_item", uniqueConstraints = @UniqueConstraint(name = "uq_meal_item_entry_local",
		columnNames = { "meal_entry_id", "local_id" }))
public class MealItem {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "meal_entry_id", nullable = false)
	private MealEntry mealEntry;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id")
	private Food food;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "recipe_id")
	private Recipe recipe;

	@Column(name = "amount", nullable = false)
	private BigDecimal amount;

	@Column(name = "unit_override")
	private String unitOverride;

	@Column(name = "note")
	private String note;

	/** Cihazın kaleme verdiği kimlik (G-72); aynı öğün kaydında tekrarı önler. */
	@Column(name = "local_id", length = 36)
	private String localId;

	@Column(name = "calories")
	private BigDecimal calories;

	@Column(name = "protein")
	private BigDecimal protein;

	@Column(name = "carbs")
	private BigDecimal carbs;

	@Column(name = "fat")
	private BigDecimal fat;

	@Column(name = "sugar")
	private BigDecimal sugar = BigDecimal.ZERO;

	@Column(name = "fiber")
	private BigDecimal fiber = BigDecimal.ZERO;

	@Column(name = "sodium")
	private BigDecimal sodium = BigDecimal.ZERO;

	@Column(name = "cholesterol")
	private BigDecimal cholesterol = BigDecimal.ZERO;

	@Column(name = "potassium")
	private BigDecimal potassium = BigDecimal.ZERO;

	@Column(name = "sat_fat")
	private BigDecimal satFat = BigDecimal.ZERO;

	@Column(name = "trans_fat")
	private BigDecimal transFat = BigDecimal.ZERO;

	@Column(name = "mono_fat")
	private BigDecimal monoFat = BigDecimal.ZERO;

	@Column(name = "poly_fat")
	private BigDecimal polyFat = BigDecimal.ZERO;

	/**
	 * Veri bütünlüğü kontrolü (Bulgu #7). Bir öğe ya bir besindir (food) ya da bir
	 * tariftir (recipe).
	 */
	@AssertTrue(message = "{validation.nutrition.food-or-recipe-required}")
	public boolean isValid() {
		return (food == null) != (recipe == null);
	}

	// --- Constructors ---
	public MealItem() {
	}

	public MealItem(MealEntry mealEntry, Food food, BigDecimal amount) {
		this.mealEntry = mealEntry;
		this.food = food;
		this.amount = amount;
	}

	public MealItem(MealEntry mealEntry, Recipe recipe, BigDecimal amount) {
		this.mealEntry = mealEntry;
		this.recipe = recipe;
		this.amount = amount;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public MealEntry getMealEntry() {
		return mealEntry;
	}

	public void setMealEntry(MealEntry mealEntry) {
		this.mealEntry = mealEntry;
	}

	public Food getFood() {
		return food;
	}

	public void setFood(Food food) {
		this.food = food;
	}

	public Recipe getRecipe() {
		return recipe;
	}

	public void setRecipe(Recipe recipe) {
		this.recipe = recipe;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public String getUnitOverride() {
		return unitOverride;
	}

	public void setUnitOverride(String unitOverride) {
		this.unitOverride = unitOverride;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public String getLocalId() {
		return localId;
	}

	public void setLocalId(String localId) {
		this.localId = localId;
	}

	public BigDecimal getCalories() {
		return calories;
	}

	public void setCalories(BigDecimal calories) {
		this.calories = calories;
	}

	public BigDecimal getProtein() {
		return protein;
	}

	public void setProtein(BigDecimal protein) {
		this.protein = protein;
	}

	public BigDecimal getCarbs() {
		return carbs;
	}

	public void setCarbs(BigDecimal carbs) {
		this.carbs = carbs;
	}

	public BigDecimal getFat() {
		return fat;
	}

	public void setFat(BigDecimal fat) {
		this.fat = fat;
	}

	public BigDecimal getSugar() {
		return sugar;
	}

	public void setSugar(BigDecimal sugar) {
		this.sugar = sugar;
	}

	public BigDecimal getFiber() {
		return fiber;
	}

	public void setFiber(BigDecimal fiber) {
		this.fiber = fiber;
	}

	public BigDecimal getSodium() {
		return sodium;
	}

	public void setSodium(BigDecimal sodium) {
		this.sodium = sodium;
	}

	public BigDecimal getCholesterol() {
		return cholesterol;
	}

	public void setCholesterol(BigDecimal cholesterol) {
		this.cholesterol = cholesterol;
	}

	public BigDecimal getPotassium() {
		return potassium;
	}

	public void setPotassium(BigDecimal potassium) {
		this.potassium = potassium;
	}

	public BigDecimal getSatFat() {
		return satFat;
	}

	public void setSatFat(BigDecimal satFat) {
		this.satFat = satFat;
	}

	public BigDecimal getTransFat() {
		return transFat;
	}

	public void setTransFat(BigDecimal transFat) {
		this.transFat = transFat;
	}

	public BigDecimal getMonoFat() {
		return monoFat;
	}

	public void setMonoFat(BigDecimal monoFat) {
		this.monoFat = monoFat;
	}

	public BigDecimal getPolyFat() {
		return polyFat;
	}

	public void setPolyFat(BigDecimal polyFat) {
		this.polyFat = polyFat;
	}

}
