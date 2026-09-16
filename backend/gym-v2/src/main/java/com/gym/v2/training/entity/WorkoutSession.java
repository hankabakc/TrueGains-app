package com.gym.v2.training.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * GYMAPP-V2 İdman Oturumu: Birden fazla egzersiz logunu tek bir oturum altında toplar.
 */
@Entity
@Table(name = "workout_sessions", uniqueConstraints = @UniqueConstraint(name = "uq_workout_sessions_user_local",
		columnNames = { "user_id", "local_id" }))
public class WorkoutSession {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@Column(nullable = false)
	private String workoutDayName;

	@Column(nullable = false)
	private Integer totalSeconds;

	@OneToMany(mappedBy = "session", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<WorkoutLog> logs = new ArrayList<>();

	@Column(name = "training_block_id")
	private Long trainingBlockId;

	@Column(name = "workout_day_id")
	private Long workoutDayId;

	/**
	 * Cihazın ürettiği kimlik; aynı kullanıcıdan aynı kimlikle ikinci oturum açılmaz
	 * (G-79).
	 */
	@Column(name = "local_id", length = 36)
	private String localId;

	@Column(nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	/**
	 * Zaman damgasını dışarıdan (Service/Clock) atamak için kullanılır.
	 * @param now Mevcut zaman
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
	}

	public WorkoutSession() {
	}

	public WorkoutSession(AppUser user, String workoutDayName, Integer totalSeconds) {
		this.user = user;
		this.workoutDayName = workoutDayName;
		this.totalSeconds = totalSeconds;
	}

	// Helper method for bi-directional relationship
	public void addLog(WorkoutLog log) {
		logs.add(log);
		log.setSession(this);
	}

	// Getter ve Setter'lar
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

	public String getWorkoutDayName() {
		return workoutDayName;
	}

	public void setWorkoutDayName(String workoutDayName) {
		this.workoutDayName = workoutDayName;
	}

	public Integer getTotalSeconds() {
		return totalSeconds;
	}

	public void setTotalSeconds(Integer totalSeconds) {
		this.totalSeconds = totalSeconds;
	}

	public List<WorkoutLog> getLogs() {
		return logs;
	}

	public void setLogs(List<WorkoutLog> logs) {
		this.logs = logs;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Long getTrainingBlockId() {
		return trainingBlockId;
	}

	public void setTrainingBlockId(Long trainingBlockId) {
		this.trainingBlockId = trainingBlockId;
	}

	public Long getWorkoutDayId() {
		return workoutDayId;
	}

	public void setWorkoutDayId(Long workoutDayId) {
		this.workoutDayId = workoutDayId;
	}

	public String getLocalId() {
		return localId;
	}

	public void setLocalId(String localId) {
		this.localId = localId;
	}

}
