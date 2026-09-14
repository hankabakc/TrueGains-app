package com.gym.v2.training.entity;

import jakarta.persistence.*;
import java.util.List;

/**
 * GYMAPP-V2 Antrenman Günü: Bir bloğun içindeki tekil antrenman günlerini temsil eder.
 * Örn: "1. Gün - Göğüs & Omuz", "2. Gün - Bacak"
 */
@Entity
@Table(name = "workout_days")
public class WorkoutDay {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "block_id", nullable = false)
	private TrainingBlock trainingBlock; // Hangi programa bağlı?

	@Column(nullable = false)
	private String name; // Günün adı

	@Column(nullable = false)
	private Integer dayOrder; // Haftalık sıralama (1, 2, 3...)

	@Column(name = "is_magnet_enabled", nullable = false)
	private Boolean isMagnetEnabled = true;

	// Bir antrenman gününde birden fazla egzersiz bulunur.
	@OneToMany(mappedBy = "workoutDay", cascade = CascadeType.ALL, orphanRemoval = true)
	@OrderBy("orderIndex ASC")
	@org.hibernate.annotations.Fetch(org.hibernate.annotations.FetchMode.SUBSELECT)
	private List<WorkoutExercise> exercises;

	// Hibernate için boş constructor
	public WorkoutDay() {
	}

	// Manuel Constructor (Lombok Yasak)
	public WorkoutDay(TrainingBlock trainingBlock, String name, Integer dayOrder) {
		this.trainingBlock = trainingBlock;
		this.name = name;
		this.dayOrder = dayOrder;
	}

	// Getter ve Setter'lar
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public TrainingBlock getTrainingBlock() {
		return trainingBlock;
	}

	public void setTrainingBlock(TrainingBlock trainingBlock) {
		this.trainingBlock = trainingBlock;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Integer getDayOrder() {
		return dayOrder;
	}

	public void setDayOrder(Integer dayOrder) {
		this.dayOrder = dayOrder;
	}

	public List<WorkoutExercise> getExercises() {
		return exercises;
	}

	public void setExercises(List<WorkoutExercise> exercises) {
		this.exercises = exercises;
	}

	// Helper methods for bidirectional relationship
	public void addExercise(WorkoutExercise exercise) {
		if (this.exercises == null) {
			this.exercises = new java.util.ArrayList<>();
		}
		this.exercises.add(exercise);
		exercise.setWorkoutDay(this);
	}

	public void removeExercise(WorkoutExercise exercise) {
		if (this.exercises != null) {
			this.exercises.remove(exercise);
			exercise.setWorkoutDay(null);
		}
	}

	public Boolean getIsMagnetEnabled() {
		return isMagnetEnabled;
	}

	public void setIsMagnetEnabled(Boolean magnetEnabled) {
		isMagnetEnabled = magnetEnabled;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}
		WorkoutDay that = (WorkoutDay) o;
		return id != null && id.equals(that.id);
	}

	@Override
	public int hashCode() {
		return getClass().hashCode();
	}

}
