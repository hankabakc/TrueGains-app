package com.gym.v2.training.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * GYMAPP-V2 Antrenman Logu: Sporcunun GERÇEKLEŞEN performansını tutar. Her bir set için
 * ayrı bir log kaydı tutulur.
 */
@Entity
@Table(name = "workout_logs", indexes = { @Index(name = "idx_workout_log_exercise", columnList = "workout_exercise_id"),
		@Index(name = "idx_workout_log_session", columnList = "session_id") })
public class WorkoutLog {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "workout_exercise_id", nullable = false)
	private WorkoutExercise workoutExercise;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "session_id")
	private WorkoutSession session;

	@Column(nullable = false)
	private Integer setIndex;

	@Column(name = "actual_weight", precision = 10, scale = 2, nullable = false)
	private BigDecimal actualWeight;

	@Column(nullable = false)
	private Integer actualReps;

	private Integer rpe;

	private Integer durationSeconds;

	@Column(nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "performed_exercise_id")
	private Exercise performedExercise;

	/**
	 * Zaman damgasını dışarıdan (Service/Clock) atamak için kullanılır.
	 * @param now Mevcut zaman
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
	}

	/**
	 * Varsayılan yapılandırıcı. JPA gereksinimi için eklenmiştir. Dışarıdan izinsiz nesne
	 * üretimini engellemek için protected yapılmıştır.
	 */
	protected WorkoutLog() {
	}

	/**
	 * Yeni bir set log kaydı oluşturur.
	 */
	public WorkoutLog(WorkoutExercise workoutExercise, Integer setIndex, BigDecimal actualWeight, Integer actualReps,
			Integer rpe, Integer durationSeconds) {
		this();
		this.workoutExercise = workoutExercise;
		this.setIndex = setIndex;
		this.actualWeight = actualWeight;
		this.actualReps = actualReps;
		this.rpe = rpe;
		this.durationSeconds = durationSeconds;
	}

	// Getters
	public Long getId() {
		return id;
	}

	public WorkoutExercise getWorkoutExercise() {
		return workoutExercise;
	}

	public WorkoutSession getSession() {
		return session;
	}

	public Integer getSetIndex() {
		return setIndex;
	}

	public BigDecimal getActualWeight() {
		return actualWeight;
	}

	public Integer getActualReps() {
		return actualReps;
	}

	public Integer getRpe() {
		return rpe;
	}

	public Integer getDurationSeconds() {
		return durationSeconds;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	/**
	 * Session bağlantısı kurmak için dahili paket erişimli metot.
	 * @param session Logun bağlı olduğu oturum.
	 */
	void setSession(WorkoutSession session) {
		this.session = session;
	}

	public Exercise getPerformedExercise() {
		return performedExercise;
	}

	public void setPerformedExercise(Exercise performedExercise) {
		this.performedExercise = performedExercise;
	}

}
