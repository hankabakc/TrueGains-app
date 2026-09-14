package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.CoachEntity;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Antrenör galeri öğesi (Sertifika, gelişim görseli vb.) Bulgu #2 & #3: Zaman yönetimi,
 * TIMESTAMPTZ ve setter temizliği yapıldı.
 */
@Entity
@Table(name = "coach_gallery")
public class CoachGallery {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = false)
	private CoachEntity coach;

	@Column(name = "image_url", nullable = false, length = 500)
	private String imageUrl;

	@Column(name = "is_student_progress")
	private Boolean isStudentProgress = false;

	@Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	public CoachGallery() {
	}

	public CoachGallery(CoachEntity coach, String imageUrl, Boolean isStudentProgress) {
		this.coach = coach;
		this.imageUrl = imageUrl;
		this.isStudentProgress = isStudentProgress;
	}

	/**
	 * Kayıt öncesi zaman damgasını set eder.
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
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

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public Boolean getIsStudentProgress() {
		return isStudentProgress;
	}

	public void setIsStudentProgress(Boolean isStudentProgress) {
		this.isStudentProgress = isStudentProgress;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

}
