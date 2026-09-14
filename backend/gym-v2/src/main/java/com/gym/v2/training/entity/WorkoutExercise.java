package com.gym.v2.training.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.List;

/**
 * GYMAPP-V2 Antrenman Egzersizi: Koçun belirlediği "HEDEF" değerleri tutar. Dinlenme
 * süresi ve Süper Set desteği burada kurgulanmıştır.
 */
@Entity
@Table(name = "workout_exercises")
public class WorkoutExercise {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "day_id", nullable = false)
	private WorkoutDay workoutDay; // Hangi güne bağlı?

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "exercise_id", nullable = false)
	private Exercise exercise; // Kütüphanedeki asıl egzersiz

	// Hedeflenen Değerler (Target)
	@Column(name = "target_sets")
	private Integer targetSets; // Hedef Set (örn: 4)

	@Column(name = "target_reps")
	private String targetReps; // Hedef Tekrar (örn: "8-12" veya "15")

	@Column(name = "target_weight", precision = 10, scale = 2)
	private BigDecimal targetWeight; // Hedef Kilo (örn: 100.0)

	// Modern Özellikler (GYMAPP-V2 Masterpiece)
	@Column(name = "rest_time_seconds")
	private Integer restTimeSeconds; // Set arası dinlenme süresi (örn: 60)

	// Süper Set Desteği: Aynı ID'ye sahip egzersizler birlikte gösterilir (A1,
	// A2...)
	@Column(name = "superset_group_id")
	private String supersetGroupId;

	@Column(name = "order_index", nullable = false)
	private Integer orderIndex; // Gün içindeki sıralama

	@Column(name = "coach_notes", length = 500)
	private String coachNotes; // Koçun bu hareket özelindeki uyarısı

	@Column(name = "is_to_failure")
	private Boolean isToFailure; // Tükeniş seti mi? (True ise set tükenişe kadar yapılır)

	// Sporcunun bu egzersiz için yaptığı tüm set kayıtları (Loglar)
	@OneToMany(mappedBy = "workoutExercise", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<WorkoutLog> logs;

	// Hibernate için boş constructor
	public WorkoutExercise() {
	}

	// Manuel Constructor (Lombok Yasak)
	public WorkoutExercise(WorkoutDay workoutDay, Exercise exercise, Integer targetSets, String targetReps,
			BigDecimal targetWeight, Integer restTimeSeconds, String supersetGroupId, Integer orderIndex,
			Boolean isToFailure) {
		this.workoutDay = workoutDay;
		this.exercise = exercise;
		this.targetSets = targetSets;
		this.targetReps = targetReps;
		this.targetWeight = targetWeight;
		this.restTimeSeconds = restTimeSeconds;
		this.supersetGroupId = supersetGroupId;
		this.orderIndex = orderIndex;
		this.isToFailure = isToFailure;
	}

	// Getter ve Setter'lar
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public WorkoutDay getWorkoutDay() {
		return workoutDay;
	}

	public void setWorkoutDay(WorkoutDay workoutDay) {
		this.workoutDay = workoutDay;
	}

	public Exercise getExercise() {
		return exercise;
	}

	public void setExercise(Exercise exercise) {
		this.exercise = exercise;
	}

	public Integer getTargetSets() {
		return targetSets;
	}

	public void setTargetSets(Integer targetSets) {
		this.targetSets = targetSets;
	}

	public String getTargetReps() {
		return targetReps;
	}

	public void setTargetReps(String targetReps) {
		this.targetReps = targetReps;
	}

	public BigDecimal getTargetWeight() {
		return targetWeight;
	}

	public void setTargetWeight(BigDecimal targetWeight) {
		this.targetWeight = targetWeight;
	}

	public Integer getRestTimeSeconds() {
		return restTimeSeconds;
	}

	public void setRestTimeSeconds(Integer restTimeSeconds) {
		this.restTimeSeconds = restTimeSeconds;
	}

	public String getSupersetGroupId() {
		return supersetGroupId;
	}

	public void setSupersetGroupId(String supersetGroupId) {
		this.supersetGroupId = supersetGroupId;
	}

	public Integer getOrderIndex() {
		return orderIndex;
	}

	public void setOrderIndex(Integer orderIndex) {
		this.orderIndex = orderIndex;
	}

	public String getCoachNotes() {
		return coachNotes;
	}

	public void setCoachNotes(String coachNotes) {
		this.coachNotes = coachNotes;
	}

	public Boolean getIsToFailure() {
		return isToFailure;
	}

	public void setIsToFailure(Boolean isToFailure) {
		this.isToFailure = isToFailure;
	}

	public List<WorkoutLog> getLogs() {
		return logs;
	}

	public void setLogs(List<WorkoutLog> logs) {
		this.logs = logs;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}
		WorkoutExercise that = (WorkoutExercise) o;
		return id != null && id.equals(that.id);
	}

	@Override
	public int hashCode() {
		return getClass().hashCode();
	}

}
