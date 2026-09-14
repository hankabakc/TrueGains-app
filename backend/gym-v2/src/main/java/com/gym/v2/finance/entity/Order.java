package com.gym.v2.finance.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Ödeme Siparişleri (Order) Entity Sınıfı. Lombok yasak olduğu için getter/setter
 * metotları ve yapıcılar el ile eklenmiştir.
 */
@Entity
@Table(name = "checkout_order")
public class Order {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private AppUser client;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "package_id", nullable = false)
	private SubscriptionPackage pkg;

	@Column(nullable = false)
	private BigDecimal amount;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private OrderStatus status;

	@Column(name = "checkout_session_id")
	private String checkoutSessionId;

	@Column(name = "created_at", columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	// --- Constructors ---

	public Order() {
	}

	public Order(Long id, AppUser client, SubscriptionPackage pkg, BigDecimal amount, OrderStatus status,
			String checkoutSessionId, Instant createdAt) {
		this.id = id;
		this.client = client;
		this.pkg = pkg;
		this.amount = amount;
		this.status = status;
		this.checkoutSessionId = checkoutSessionId;
		this.createdAt = createdAt;
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

	public SubscriptionPackage getPkg() {
		return pkg;
	}

	public void setPkg(SubscriptionPackage pkg) {
		this.pkg = pkg;
	}

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public OrderStatus getStatus() {
		return status;
	}

	public void setStatus(OrderStatus status) {
		this.status = status;
	}

	public String getCheckoutSessionId() {
		return checkoutSessionId;
	}

	public void setCheckoutSessionId(String checkoutSessionId) {
		this.checkoutSessionId = checkoutSessionId;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Instant createdAt) {
		this.createdAt = createdAt;
	}

}
