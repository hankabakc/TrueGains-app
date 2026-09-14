package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Kullanıcı Besin Değeri Ezme Entity (UserFoodOverride) Kullanıcının belirli bir besin
 * için girdiği özel değerleri tutar (Requirement 9).
 */
@Entity
@Table(name = "user_food_override", uniqueConstraints = { @UniqueConstraint(columnNames = { "user_id", "food_id" }) })
public class UserFoodOverride {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "food_id", nullable = false)
	private Food food;

	private BigDecimal calories;

	private BigDecimal protein;

	private BigDecimal carbs;

	private BigDecimal fat;

	private BigDecimal sugar;

	private BigDecimal fiber;

	private BigDecimal sodium;

	private BigDecimal cholesterol;

	private BigDecimal potassium;

	@Column(name = "sat_fat")
	private BigDecimal satFat;

	@Column(name = "trans_fat")
	private BigDecimal transFat;

	@Column(name = "mono_fat")
	private BigDecimal monoFat;

	@Column(name = "poly_fat")
	private BigDecimal polyFat;

	@Column(name = "created_at", updatable = false)
	private LocalDateTime createdAt;

	@Column(name = "updated_at")
	private LocalDateTime updatedAt;

	// --- Constructors ---

	public UserFoodOverride() {
	}

	public UserFoodOverride(AppUser user, Food food) {
		this();
		this.user = user;
		this.food = food;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public AppUser getUser() {
		return user;
	}

	public void setUser(AppUser user) {
		this.user = user;
	}

	public Food getFood() {
		return food;
	}

	public void setFood(Food food) {
		this.food = food;
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

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public LocalDateTime getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(LocalDateTime updatedAt) {
		this.updatedAt = updatedAt;
	}

}
