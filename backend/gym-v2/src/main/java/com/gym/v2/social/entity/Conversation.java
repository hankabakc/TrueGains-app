package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Kullanıcı ve Antrenör arasındaki sohbet oturumu. Bulgu #2: Zaman yönetimi ve
 * TIMESTAMPTZ geçişi yapıldı.
 */
@Entity
@Table(name = "conversation")
public class Conversation {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private AppUser client;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = false)
	private AppUser coach;

	@Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	@Column(name = "last_message_at", columnDefinition = "TIMESTAMPTZ")
	private Instant lastMessageAt;

	@Column(name = "is_active")
	private Boolean isActive = true;

	public Conversation() {
	}

	/**
	 * Kayıt öncesi zaman damgalarını set eder.
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
		this.lastMessageAt = now;
	}

	/**
	 * Son mesaj zamanını günceller.
	 */
	public void updateLastMessageAt(Instant now) {
		this.lastMessageAt = now;
	}

	// Manual Getters and Setters
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public AppUser getClient() {
		return client;
	}

	public void setClient(AppUser client) {
		this.client = client;
	}

	public AppUser getCoach() {
		return coach;
	}

	public void setCoach(AppUser coach) {
		this.coach = coach;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getLastMessageAt() {
		return lastMessageAt;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public void setIsActive(Boolean isActive) {
		this.isActive = isActive;
	}

}
