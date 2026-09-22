package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Su Tüketimi Entity (WaterIntake)
 */
@Entity
@Table(name = "water_intake", uniqueConstraints = @UniqueConstraint(name = "uq_water_intake_user_local",
		columnNames = { "user_id", "local_id" }))
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

	/** Cihazın kayda verdiği kimlik (G-86); tekrar gelen istek ikinci satır açmaz. */
	@Column(name = "local_id", length = 36)
	private String localId;

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

	public String getLocalId() {
		return localId;
	}

	public void setLocalId(String localId) {
		this.localId = localId;
	}

}
