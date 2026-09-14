package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Antrenör Öğrenci Gelişim (Before-After) Entity
 */
@Entity
@Table(name = "coach_student_progress")
public class CoachStudentProgress {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = false)
	private CoachEntity coach;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private ClientEntity client;

	@Column(name = "student_nickname", nullable = false)
	private String studentNickname;

	@Column(name = "before_image_url", nullable = false, length = 500)
	private String beforeImageUrl;

	@Column(name = "after_image_url", nullable = false, length = 500)
	private String afterImageUrl;

	@Column(columnDefinition = "TEXT")
	private String description;

	@Column(nullable = false, length = 50)
	private String status; // PENDING, APPROVED, REJECTED

	@Column(name = "created_at")
	private Instant createdAt;

	@Column(name = "updated_at")
	private Instant updatedAt;

	public CoachStudentProgress() {
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public CoachEntity getCoach() {
		return coach;
	}

	public void setCoach(CoachEntity coach) {
		this.coach = coach;
	}

	public ClientEntity getClient() {
		return client;
	}

	public void setClient(ClientEntity client) {
		this.client = client;
	}

	public String getStudentNickname() {
		return studentNickname;
	}

	public void setStudentNickname(String studentNickname) {
		this.studentNickname = studentNickname;
	}

	public String getBeforeImageUrl() {
		return beforeImageUrl;
	}

	public void setBeforeImageUrl(String beforeImageUrl) {
		this.beforeImageUrl = beforeImageUrl;
	}

	public String getAfterImageUrl() {
		return afterImageUrl;
	}

	public void setAfterImageUrl(String afterImageUrl) {
		this.afterImageUrl = afterImageUrl;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
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

	@PrePersist
	protected void onCreate() {
		this.createdAt = Instant.now();
		this.updatedAt = Instant.now();
	}

	@PreUpdate
	protected void onUpdate() {
		this.updatedAt = Instant.now();
	}

}
