package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "user_block")
public class UserBlock {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "blocker_id", nullable = false)
	private AppUser blocker;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "blocked_id", nullable = false)
	private AppUser blocked;

	@Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	public UserBlock() {
	}

	public void onPersist(Instant now) {
		this.createdAt = now;
	}

	public Long getId() {
		return this.id;
	}

	public AppUser getBlocker() {
		return this.blocker;
	}

	public void setBlocker(AppUser blocker) {
		this.blocker = blocker;
	}

	public AppUser getBlocked() {
		return this.blocked;
	}

	public void setBlocked(AppUser blocked) {
		this.blocked = blocked;
	}

	public Instant getCreatedAt() {
		return this.createdAt;
	}

}
