package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

/**
 * Yemek Şablonu İçeriği Entity (MealTemplateIngredient)
 */
@Entity
@Table(name = "meal_template_ingredient")
public class MealTemplateIngredient {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "meal_template_id", nullable = false)
	private MealTemplate mealTemplate;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id", nullable = true)
	private Food food;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "recipe_id")
	private Recipe recipe;

	@Column(nullable = false)
	private BigDecimal amount;

	@Column(name = "ignore_override", nullable = false)
	private boolean ignoreOverride = false;

	// --- Constructors ---

	public MealTemplateIngredient() {
	}

	public MealTemplateIngredient(MealTemplate mealTemplate, Food food, BigDecimal amount, boolean ignoreOverride) {
		this.mealTemplate = mealTemplate;
		this.food = food;
		this.amount = amount;
		this.ignoreOverride = ignoreOverride;
	}

	public MealTemplateIngredient(MealTemplate mealTemplate, Recipe recipe, BigDecimal amount) {
		this.mealTemplate = mealTemplate;
		this.recipe = recipe;
		this.amount = amount;
		this.ignoreOverride = true;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public MealTemplate getMealTemplate() {
		return mealTemplate;
	}

	public void setMealTemplate(MealTemplate mealTemplate) {
		this.mealTemplate = mealTemplate;
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

	public boolean isIgnoreOverride() {
		return ignoreOverride;
	}

	public void setIgnoreOverride(boolean ignoreOverride) {
		this.ignoreOverride = ignoreOverride;
	}

}
