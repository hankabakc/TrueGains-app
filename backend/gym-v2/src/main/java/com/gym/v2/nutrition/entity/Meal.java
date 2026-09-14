package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Öğün Entity (Meal) Belirli bir diyet programına ait öğünleri temsil eder (Kahvaltı,
 * Öğle vb).
 */
@Entity
@Table(name = "meal")
public class Meal {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "diet_day_id", nullable = false)
	private DietDay dietDay;

	@Enumerated(EnumType.STRING)
	@Column(name = "meal_type", nullable = false)
	private MealType mealType;

	@Column(name = "order_index")
	private int orderIndex;

	@OneToMany(mappedBy = "meal", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<MealIngredient> ingredients = new ArrayList<>();

	// --- Constructors ---

	public Meal() {
	}

	public Meal(DietDay dietDay, MealType mealType, int orderIndex) {
		this.dietDay = dietDay;
		this.mealType = mealType;
		this.orderIndex = orderIndex;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public DietDay getDietDay() {
		return dietDay;
	}

	public void setDietDay(DietDay dietDay) {
		this.dietDay = dietDay;
	}

	public MealType getMealType() {
		return mealType;
	}

	public void setMealType(MealType mealType) {
		this.mealType = mealType;
	}

	public int getOrderIndex() {
		return orderIndex;
	}

	public void setOrderIndex(int orderIndex) {
		this.orderIndex = orderIndex;
	}

	public List<MealIngredient> getIngredients() {
		return ingredients;
	}

	public void setIngredients(List<MealIngredient> ingredients) {
		this.ingredients = ingredients;
	}

}
