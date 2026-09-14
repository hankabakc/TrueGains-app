package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Özel Bardak Entity (CustomGlass)
 */
@Entity
@Table(name = "custom_glasses")
public class CustomGlass {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	@Column(name = "name", nullable = false, length = 50)
	private String name;

	@Column(name = "size_ml", nullable = false)
	private Integer sizeMl;

	@Column(name = "created_at", updatable = false)
	private LocalDateTime createdAt;

	public CustomGlass() {
	}

	public CustomGlass(AppUser user, String name, Integer sizeMl) {
		this();
		this.user = user;
		this.name = name;
		this.sizeMl = sizeMl;
	}

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

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public Integer getSizeMl() {
		return sizeMl;
	}

	public void setSizeMl(Integer sizeMl) {
		this.sizeMl = sizeMl;
	}

	public LocalDateTime getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(LocalDateTime createdAt) {
		this.createdAt = createdAt;
	}

}
