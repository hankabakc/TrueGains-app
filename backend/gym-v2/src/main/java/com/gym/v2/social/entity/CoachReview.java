package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.security.EncryptionConverter;
import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.Instant;

/**
 * Antrenör değerlendirmesi ve yorumu. Bulgu #5: Validasyonlar ve hata yönetimi
 * iyileştirildi.
 */
@Entity
@Table(name = "coach_review")
public class CoachReview {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = false)
	private CoachEntity coach;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private ClientEntity client;

	@Min(value = 1, message = "{validation.review.rating.min}")
	@Max(value = 5, message = "{validation.review.rating.max}")
	@Column(nullable = false)
	private Integer rating;

	@Column(columnDefinition = "TEXT")
	@Convert(converter = EncryptionConverter.class)
	private String comment;

	@Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	public CoachReview() {
	}

	public CoachReview(CoachEntity coach, ClientEntity client, Integer rating, String comment) {
		this.coach = coach;
		this.client = client;
		this.setRating(rating);
		this.comment = comment;
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

	public ClientEntity getClient() {
		return client;
	}

	public void setClient(ClientEntity client) {
		this.client = client;
	}

	public Integer getRating() {
		return rating;
	}

	public void setRating(Integer rating) {
		if (rating == null || rating < 1 || rating > 5) {
			throw new BadRequestException("validation.review.rating.invalid");
		}
		this.rating = rating;
	}

	public String getComment() {
		return comment;
	}

	public void setComment(String comment) {
		this.comment = comment;
	}

	@Column(name = "package_name", length = 255)
	private String packageName;

	public String getPackageName() {
		return packageName;
	}

	public void setPackageName(String packageName) {
		this.packageName = packageName;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

}
