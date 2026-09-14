package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.ClientEntity;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Sporcu Galerisi (Timeline) Entity
 */
@Entity
@Table(name = "client_gallery")
public class ClientGallery {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private ClientEntity client;

	@Column(name = "image_url", nullable = false, length = 500)
	private String imageUrl;

	@Column(name = "created_at")
	private Instant createdAt;

	public ClientGallery() {
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

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Instant createdAt) {
		this.createdAt = createdAt;
	}

	@PrePersist
	protected void onCreate() {
		this.createdAt = Instant.now();
	}

}
