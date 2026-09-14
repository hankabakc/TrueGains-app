package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Öğün Girdisi (MealEntry) Kullanıcının belirli bir tarihte (örneğin bugün) gerçekten
 * yediği öğünlerin makro ve kalori loglarını tutar.
 */
@Entity
@Table(name = "meal_entry")
public class MealEntry {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private AppUser client;

	@Column(name = "planned_meal_id")
	private Long plannedMealId; // Diyet programındaki spesifik öğün (Meal) referansı
								// (opsiyonel)

	@Enumerated(EnumType.STRING)
	@Column(name = "meal_type", nullable = false)
	private MealType mealType = MealType.OTHER;

	// Bulgu #1: Instant + TIMESTAMPTZ Geçişi
	@Column(name = "taken_datetime", columnDefinition = "TIMESTAMPTZ")
	private Instant takenDatetime;

	@Column(name = "photo_url", length = 500)
	private String photoUrl;

	@Column(name = "calories")
	private BigDecimal calories = BigDecimal.ZERO;

	@Column(name = "protein")
	private BigDecimal protein = BigDecimal.ZERO;

	@Column(name = "carbs")
	private BigDecimal carbs = BigDecimal.ZERO;

	@Column(name = "fat")
	private BigDecimal fat = BigDecimal.ZERO;

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

	@Column(name = "notes")
	private String notes;

	@OneToMany(mappedBy = "mealEntry", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<MealItem> items = new ArrayList<>();

	// --- Constructors ---
	public MealEntry() {
	}

	public MealEntry(AppUser client) {
		this();
		this.client = client;
	}

	// Bulgu #6 kapsamında bu constructor servis katmanında yönetilecektir.
	public MealEntry(AppUser client, Instant takenDatetime, MealType mealType) {
		this();
		this.client = client;
		this.takenDatetime = takenDatetime;
		this.mealType = mealType;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public AppUser getClient() {
		return client;
	}

	public void setClient(AppUser client) {
		this.client = client;
	}

	public Long getPlannedMealId() {
		return plannedMealId;
	}

	public void setPlannedMealId(Long plannedMealId) {
		this.plannedMealId = plannedMealId;
	}

	public MealType getMealType() {
		return mealType;
	}

	public void setMealType(MealType mealType) {
		this.mealType = mealType;
	}

	public Instant getTakenDatetime() {
		return takenDatetime;
	}

	public void setTakenDatetime(Instant takenDatetime) {
		this.takenDatetime = takenDatetime;
	}

	public String getPhotoUrl() {
		return photoUrl;
	}

	public void setPhotoUrl(String photoUrl) {
		this.photoUrl = photoUrl;
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

	public String getNotes() {
		return notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}

	public List<MealItem> getItems() {
		return items;
	}

	public void setItems(List<MealItem> items) {
		this.items = items;
	}

	public void addItem(MealItem item) {
		items.add(item);
		item.setMealEntry(this);
	}

	public void removeItem(MealItem item) {
		items.remove(item);
		item.setMealEntry(null);
	}

}
