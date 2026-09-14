package com.gym.v2.training.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.time.LocalDate;

/**
 * GYMAPP-V2 Haftalık İlerleme: Kullanıcıların haftalık bazda antrenman başarı oranlarını
 * kalıcı olarak tutar.
 */
@Entity
@Table(name = "weekly_progress", uniqueConstraints = { @UniqueConstraint(name = "uq_weekly_progress",
		columnNames = { "user_id", "training_block_id", "week_start_date" }) })
public class WeeklyProgress {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "training_block_id", nullable = false)
	private Long trainingBlockId;

	@Column(name = "week_start_date", nullable = false)
	private LocalDate weekStartDate;

	@Column(name = "target_days", nullable = false)
	private Integer targetDays = 0;

	@Column(name = "completed_days", nullable = false)
	private Integer completedDays = 0;

	@Column(name = "completion_rate", nullable = false)
	private Double completionRate = 0.0;

	@Column(name = "created_at", nullable = false)
	private Instant createdAt = Instant.now();

	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt = Instant.now();

	// Hibernate için boş constructor
	public WeeklyProgress() {
	}

	// Manuel Constructor (Lombok Yasak)
	public WeeklyProgress(Long userId, Long trainingBlockId, LocalDate weekStartDate, Integer targetDays,
			Integer completedDays, Double completionRate) {
		this.userId = userId;
		this.trainingBlockId = trainingBlockId;
		this.weekStartDate = weekStartDate;
		this.targetDays = targetDays;
		this.completedDays = completedDays;
		this.completionRate = completionRate;
		this.createdAt = Instant.now();
		this.updatedAt = Instant.now();
	}

	// Getter ve Setter'lar
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Long getUserId() {
		return userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public Long getTrainingBlockId() {
		return trainingBlockId;
	}

	public void setTrainingBlockId(Long trainingBlockId) {
		this.trainingBlockId = trainingBlockId;
	}

	public LocalDate getWeekStartDate() {
		return weekStartDate;
	}

	public void setWeekStartDate(LocalDate weekStartDate) {
		this.weekStartDate = weekStartDate;
	}

	public Integer getTargetDays() {
		return targetDays;
	}

	public void setTargetDays(Integer targetDays) {
		this.targetDays = targetDays;
	}

	public Integer getCompletedDays() {
		return completedDays;
	}

	public void setCompletedDays(Integer completedDays) {
		this.completedDays = completedDays;
	}

	public Double getCompletionRate() {
		return completionRate;
	}

	public void setCompletionRate(Double completionRate) {
		this.completionRate = completionRate;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Instant createdAt) {
		this.createdAt = createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

	public void setUpdatedAt(Instant updatedAt) {
		this.updatedAt = updatedAt;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}
		WeeklyProgress that = (WeeklyProgress) o;
		return id != null && id.equals(that.id);
	}

	@Override
	public int hashCode() {
		return getClass().hashCode();
	}

}
