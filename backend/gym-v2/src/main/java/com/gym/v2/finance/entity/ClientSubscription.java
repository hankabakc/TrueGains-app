package com.gym.v2.finance.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDate;

/**
 * Sporcu Abonelikleri (ClientSubscription) Entity
 */
@Entity
@Table(name = "client_subscription")
public class ClientSubscription {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private AppUser client;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id")
	private AppUser coach;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "package_id", nullable = false)
	private SubscriptionPackage pkg;

	@Column(name = "start_date", nullable = false)
	private LocalDate startDate;

	@Column(name = "end_date", nullable = false)
	private LocalDate endDate;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive = true;

	// --- Constructors ---

	public ClientSubscription() {
	}

	public ClientSubscription(Long id, AppUser client, AppUser coach, SubscriptionPackage pkg, LocalDate startDate,
			LocalDate endDate, Boolean isActive) {
		this.id = id;
		this.client = client;
		this.coach = coach;
		this.pkg = pkg;
		this.startDate = startDate;
		this.endDate = endDate;
		this.isActive = isActive;
	}

	// --- Getters & Setters ---

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

	public SubscriptionPackage getPkg() {
		return pkg;
	}

	public void setPkg(SubscriptionPackage pkg) {
		this.pkg = pkg;
	}

	public LocalDate getStartDate() {
		return startDate;
	}

	public void setStartDate(LocalDate startDate) {
		this.startDate = startDate;
	}

	public LocalDate getEndDate() {
		return endDate;
	}

	public void setEndDate(LocalDate endDate) {
		this.endDate = endDate;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public void setIsActive(Boolean isActive) {
		this.isActive = isActive;
	}

}
