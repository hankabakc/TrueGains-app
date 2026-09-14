package com.gym.v2.auth.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Kullanıcının bir cihazına ait bildirim (FCM) anahtarı.
 * <p>
 * Daha önce token {@code app_user.fcm_token} alanında tekildi: ikinci cihazdan giren
 * kullanıcı birincinin bildirimlerini kaybediyordu. Ayrı tablo, kullanıcı başına birden
 * çok cihaza izin verir ve ölü token'ın tek tek silinebilmesini sağlar.
 * </p>
 */
@Entity
@Table(name = "user_device_token", indexes = { @Index(name = "idx_user_device_token_user", columnList = "user_id") })
public class UserDeviceToken {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@Column(nullable = false, length = 512)
	private String token;

	@Column(name = "created_at", nullable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	protected UserDeviceToken() {
	}

	public UserDeviceToken(AppUser user, String token, Instant createdAt) {
		this.user = user;
		this.token = token;
		this.createdAt = createdAt;
	}

	public Long getId() {
		return id;
	}

	public AppUser getUser() {
		return user;
	}

	public String getToken() {
		return token;
	}

	public void setUser(AppUser user) {
		this.user = user;
	}

	public void setToken(String token) {
		this.token = token;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

}
