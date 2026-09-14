package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.AssertTrue;
import java.math.BigDecimal;

/**
 * Öğün İçeriği Entity (MealIngredient) Öğünde yer alan besini ve miktarını temsil eder.
 */
@Entity
@Table(name = "meal_ingredient")
public class MealIngredient {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "meal_id", nullable = false)
	private Meal meal;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id", nullable = true)
	private Food food;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "recipe_id")
	private Recipe recipe;

	@Column(nullable = false)
	private BigDecimal amount;

	private String note;

	@Column(name = "ignore_override", nullable = false)
	private boolean ignoreOverride = false;

	private BigDecimal calories;

	private BigDecimal protein;

	private BigDecimal carbs;

	private BigDecimal fat;

	private BigDecimal sugar;

	private BigDecimal fiber;

	private BigDecimal sodium;

	private BigDecimal cholesterol;

	private BigDecimal potassium;

	/**
	 * Veri bütünlüğü kontrolü (Bulgu #8). Bir öğün bileşeni ya bir besindir (food) ya da
	 * bir tariftir (recipe).
	 */
	@AssertTrue(message = "{validation.nutrition.food-or-recipe-required}")
	public boolean isValid() {
		return (food == null) != (recipe == null);
	}

	// --- Constructors ---

	public MealIngredient() {
	}

	public MealIngredient(Meal meal, Food food, BigDecimal amount, boolean ignoreOverride) {
		this.meal = meal;
		this.food = food;
		this.amount = amount;
		this.ignoreOverride = ignoreOverride;
	}

	public MealIngredient(Meal meal, Food food, BigDecimal amount, String note, boolean ignoreOverride) {
		this.meal = meal;
		this.food = food;
		this.amount = amount;
		this.note = note;
		this.ignoreOverride = ignoreOverride;
	}

	public MealIngredient(Meal meal, Recipe recipe, BigDecimal amount, String note) {
		this.meal = meal;
		this.recipe = recipe;
		this.amount = amount;
		this.note = note;
		this.ignoreOverride = false; // Enable calculation for recipes
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Meal getMeal() {
		return meal;
	}

	public void setMeal(Meal meal) {
		this.meal = meal;
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

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public boolean isIgnoreOverride() {
		return ignoreOverride;
	}

	public void setIgnoreOverride(boolean ignoreOverride) {
		this.ignoreOverride = ignoreOverride;
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

}
