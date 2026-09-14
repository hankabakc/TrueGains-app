package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

/**
 * Kullanıcı Tarifi Malzemesi (UserRecipeIngredient)
 */
@Entity
@Table(name = "user_recipe_ingredient")
public class UserRecipeIngredient {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_recipe_id", nullable = false)
	private UserRecipe userRecipe;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id", nullable = false)
	private Food food;

	@Column(nullable = false)
	private BigDecimal amount;

	public UserRecipeIngredient() {
	}

	public UserRecipeIngredient(UserRecipe userRecipe, Food food, BigDecimal amount) {
		this.userRecipe = userRecipe;
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

	public UserRecipe getUserRecipe() {
		return userRecipe;
	}

	public void setUserRecipe(UserRecipe userRecipe) {
		this.userRecipe = userRecipe;
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
