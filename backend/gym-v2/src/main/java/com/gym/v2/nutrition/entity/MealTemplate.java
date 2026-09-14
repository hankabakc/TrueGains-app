package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Yemek Şablonu Entity (MealTemplate) Kullanıcının "Favori Kahvaltım" gibi kaydettiği
 * yemek setleri.
 */
@Entity
@Table(name = "meal_template")
public class MealTemplate {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "owner_id", nullable = false)
	private AppUser owner;

	@Column(nullable = false)
	private String name;

	@Column(name = "created_at", updatable = false)
	private LocalDateTime createdAt;

	@OneToMany(mappedBy = "mealTemplate", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<MealTemplateIngredient> ingredients = new ArrayList<>();

	@ElementCollection(targetClass = MealType.class)
	@CollectionTable(name = "meal_template_applicable_types", joinColumns = @JoinColumn(name = "meal_template_id"))
	@Column(name = "meal_type")
	@Enumerated(EnumType.STRING)
	private List<MealType> applicableMealTypes = new ArrayList<>();

	// --- Constructors ---

	public MealTemplate() {
	}

	public MealTemplate(AppUser owner, String name) {
		this();
		this.owner = owner;
		this.name = name;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public AppUser getOwner() {
		return owner;
	}

	public void setOwner(AppUser owner) {
		this.owner = owner;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public List<MealTemplateIngredient> getIngredients() {
		return ingredients;
	}

	public void setIngredients(List<MealTemplateIngredient> ingredients) {
		this.ingredients = ingredients;
	}

	public List<MealType> getApplicableMealTypes() {
		return applicableMealTypes;
	}

	public void setApplicableMealTypes(List<MealType> applicableMealTypes) {
		this.applicableMealTypes = applicableMealTypes;
	}

}
