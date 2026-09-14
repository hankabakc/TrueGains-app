package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Diyet Günü Entity (DietDay) Haftalık program içerisindeki bir günü (ör. 1. Gün,
 * Pazartesi) temsil eder.
 */
@Entity
@Table(name = "diet_day")
public class DietDay {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "diet_program_id", nullable = false)
	private DietProgram dietProgram;

	@Column(name = "day_order", nullable = false)
	private Integer dayOrder;

	@Column(nullable = false)
	private String name;

	@OneToMany(mappedBy = "dietDay", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<Meal> meals = new ArrayList<>();

	// --- Constructors ---

	public DietDay() {
	}

	public DietDay(DietProgram dietProgram, Integer dayOrder, String name) {
		this.dietProgram = dietProgram;
		this.dayOrder = dayOrder;
		this.name = name;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public DietProgram getDietProgram() {
		return dietProgram;
	}

	public void setDietProgram(DietProgram dietProgram) {
		this.dietProgram = dietProgram;
	}

	public Integer getDayOrder() {
		return dayOrder;
	}

	public void setDayOrder(Integer dayOrder) {
		this.dayOrder = dayOrder;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public List<Meal> getMeals() {
		return meals;
	}

	public void setMeals(List<Meal> meals) {
		this.meals = meals;
	}

	// Yardımcı metodlar
	public void addMeal(Meal meal) {
		meals.add(meal);
		meal.setDietDay(this);
	}

}
