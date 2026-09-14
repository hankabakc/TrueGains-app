package com.gym.v2.nutrition.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Besin Kütüphanesi Entity (Food) 100g veya birim başına varsayılan besin değerlerini
 * tutar.
 */
@Entity
@Table(name = "food")
public class Food {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false)
	private String name;

	private String brand;

	private String category;

	@Column(name = "default_unit", nullable = false)
	private String defaultUnit;

	@Column(name = "default_amount", nullable = false)
	private BigDecimal defaultAmount;

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

	@Column(name = "created_at", updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	/**
	 * Kayıt öncesi zaman damgasını set eder (Bulgu #2).
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
	}

	@Column(name = "creator_id")
	private Long creatorId;

	@Column(name = "is_global", nullable = false)
	private boolean isGlobal = true;

	@Column(unique = true)
	private String barcode;

	// --- Constructors ---

	public Food() {
	}

	public Food(String name, String defaultUnit, BigDecimal defaultAmount) {
		this();
		this.name = name;
		this.defaultUnit = defaultUnit;
		this.defaultAmount = defaultAmount;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getBrand() {
		return brand;
	}

	public void setBrand(String brand) {
		this.brand = brand;
	}

	public String getCategory() {
		return category;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public String getDefaultUnit() {
		return defaultUnit;
	}

	public void setDefaultUnit(String defaultUnit) {
		this.defaultUnit = defaultUnit;
	}

	public BigDecimal getDefaultAmount() {
		return defaultAmount;
	}

	public void setDefaultAmount(BigDecimal defaultAmount) {
		this.defaultAmount = defaultAmount;
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

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Long getCreatorId() {
		return creatorId;
	}

	public void setCreatorId(Long creatorId) {
		this.creatorId = creatorId;
	}

	public boolean isGlobal() {
		return isGlobal;
	}

	public void setGlobal(boolean global) {
		isGlobal = global;
	}

	public String getBarcode() {
		return barcode;
	}

	public void setBarcode(String barcode) {
		this.barcode = barcode;
	}

}
