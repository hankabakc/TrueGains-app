package com.gym.v2.finance.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

/**
 * Abonelik Paketleri (SubscriptionPackage) Entity
 */
@Entity
@Table(name = "subscription_package")
public class SubscriptionPackage {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false)
	private String name;

	@Column(nullable = false)
	private BigDecimal price;

	@Column(name = "duration_days", nullable = false)
	private Integer durationDays;

	@Column(name = "coach_id")
	private Long coachId;

	@Column
	private String description;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive = true;

	@Column(name = "features", columnDefinition = "TEXT")
	private String features;

	@Column(name = "quota")
	private Integer quota;

	@Column(name = "levels", length = 100)
	private String levels;

	@Column(name = "mode", length = 20)
	private String mode;

	// --- Constructors ---

	public SubscriptionPackage() {
	}

	public SubscriptionPackage(Long id, String name, BigDecimal price, Integer durationDays, Long coachId,
			String description, Boolean isActive) {
		this.id = id;
		this.name = name;
		this.price = price;
		this.durationDays = durationDays;
		this.coachId = coachId;
		this.description = description;
		this.isActive = isActive;
	}

	public SubscriptionPackage(Long id, String name, BigDecimal price, Integer durationDays, Long coachId,
			String description, Boolean isActive, String features) {
		this.id = id;
		this.name = name;
		this.price = price;
		this.durationDays = durationDays;
		this.coachId = coachId;
		this.description = description;
		this.isActive = isActive;
		this.features = features;
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

	public BigDecimal getPrice() {
		return price;
	}

	public void setPrice(BigDecimal price) {
		this.price = price;
	}

	public Integer getDurationDays() {
		return durationDays;
	}

	public void setDurationDays(Integer durationDays) {
		this.durationDays = durationDays;
	}

	public Long getCoachId() {
		return coachId;
	}

	public void setCoachId(Long coachId) {
		this.coachId = coachId;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public void setIsActive(Boolean isActive) {
		this.isActive = isActive;
	}

	public String getFeatures() {
		return features;
	}

	public void setFeatures(String features) {
		this.features = features;
	}

	public Integer getQuota() {
		return quota;
	}

	public void setQuota(Integer quota) {
		this.quota = quota;
	}

	public String getLevels() {
		return levels;
	}

	public void setLevels(String levels) {
		this.levels = levels;
	}

	public String getMode() {
		return mode;
	}

	public void setMode(String mode) {
		this.mode = mode;
	}

}
