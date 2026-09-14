package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Kullanıcıya Özel Yemek Tarifi Entity (UserRecipe) Kullanıcının global bir tarifi
 * düzenleyerek veya sıfırdan oluşturarak kaydettiği tarifler.
 */
@Entity
@Table(name = "user_recipe")
public class UserRecipe {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "original_recipe_id")
	private Recipe originalRecipe;

	@Column(nullable = false)
	private String name;

	@Column(columnDefinition = "TEXT")
	private String description;

	@Column(columnDefinition = "TEXT")
	private String instructions;

	@Column(length = 100)
	private String category;

	@Column(name = "image_url", length = 500)
	private String imageUrl;

	@Column(name = "created_at", updatable = false)
	private LocalDateTime createdAt;

	@OneToMany(mappedBy = "userRecipe", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<UserRecipeIngredient> ingredients = new ArrayList<>();

	public UserRecipe() {
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

	public Recipe getOriginalRecipe() {
		return originalRecipe;
	}

	public void setOriginalRecipe(Recipe originalRecipe) {
		this.originalRecipe = originalRecipe;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getInstructions() {
		return instructions;
	}

	public void setInstructions(String instructions) {
		this.instructions = instructions;
	}

	public String getCategory() {
		return category;
	}

	public void setCategory(String category) {
		this.category = category;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

	public List<UserRecipeIngredient> getIngredients() {
		return ingredients;
	}

	public void setIngredients(List<UserRecipeIngredient> ingredients) {
		this.ingredients = ingredients;
	}

}
