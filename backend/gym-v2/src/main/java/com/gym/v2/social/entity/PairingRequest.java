package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Kullanıcı ile Antrenör arasındaki eşleşme talebi. Güvenlik iyileştirmeleri (Zaman
 * standartları ve denetim) içerir.
 */
@Entity
@Table(name = "pairing_request")
public class PairingRequest {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Version
	private Long version;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private ClientEntity client;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = false)
	private CoachEntity coach;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private PairingStatus status = PairingStatus.PENDING;

	private String message;

	// Bulgu #1: Instant + TIMESTAMPTZ Geçişi
	@Column(name = "created_at", updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	@Column(name = "updated_at", columnDefinition = "TIMESTAMPTZ")
	private Instant updatedAt;

	public PairingRequest() {
	}

	/**
	 * Kayıt öncesi zaman damgalarını set eder (Bulgu #1).
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
		this.updatedAt = now;
	}

	/**
	 * Güncelleme öncesi zaman damgasını set eder.
	 */
	public void onUpdate(Instant now) {
		this.updatedAt = now;
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public ClientEntity getClient() {
		return client;
	}

	public void setClient(ClientEntity client) {
		this.client = client;
	}

	public CoachEntity getCoach() {
		return coach;
	}

	public void setCoach(CoachEntity coach) {
		this.coach = coach;
	}

	public PairingStatus getStatus() {
		return status;
	}

	public void setStatus(PairingStatus status) {
		this.status = status;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

}
