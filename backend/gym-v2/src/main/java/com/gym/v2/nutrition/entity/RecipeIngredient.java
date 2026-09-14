package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

/**
 * Yemek Tarifi İçerik Entity (RecipeIngredient) Bir tarifin içindeki besin maddesi ve
 * miktarı.
 */
@Entity
@Table(name = "recipe_ingredient")
public class RecipeIngredient {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "recipe_id", nullable = false)
	private Recipe recipe;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id", nullable = false)
	private Food food;

	@Column(nullable = false, precision = 10, scale = 2)
	private BigDecimal amount;

	// --- Constructors ---

	public RecipeIngredient() {
	}

	public RecipeIngredient(Recipe recipe, Food food, BigDecimal amount) {
		this.recipe = recipe;
		this.food = food;
		this.amount = amount;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Recipe getRecipe() {
		return recipe;
	}

	public void setRecipe(Recipe recipe) {
		this.recipe = recipe;
	}

	public Food getFood() {
		return food;
	}

	public void setFood(Food food) {
		this.food = food;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

}
