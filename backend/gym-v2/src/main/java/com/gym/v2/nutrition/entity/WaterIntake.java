package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Su Tüketimi Entity (WaterIntake)
 */
@Entity
@Table(name = "water_intake")
public class WaterIntake {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@Column(name = "amount_ml", nullable = false)
	private Integer amountMl;

	@Column(name = "intake_date", nullable = false)
	private LocalDate intakeDate;

	@Column(name = "created_at", updatable = false)
	private LocalDateTime createdAt;

	// --- Constructors ---

	public WaterIntake() {
	}

	public WaterIntake(AppUser user, Integer amountMl, LocalDate intakeDate) {
		this();
		this.user = user;
		this.amountMl = amountMl;
		this.intakeDate = intakeDate;
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

	public Integer getAmountMl() {
		return amountMl;
	}

	public void setAmountMl(Integer amountMl) {
		this.amountMl = amountMl;
	}

	public LocalDate getIntakeDate() {
		return intakeDate;
	}

	public void setIntakeDate(LocalDate intakeDate) {
		this.intakeDate = intakeDate;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

}
