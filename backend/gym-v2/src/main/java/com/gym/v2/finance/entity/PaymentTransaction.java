package com.gym.v2.finance.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Ödeme Hareketleri (PaymentTransaction) Entity
 */
@Entity
@Table(name = "payment_transaction")
public class PaymentTransaction {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = false)
	private AppUser client;

	@Column(nullable = false)
	private BigDecimal amount;

	@Column(nullable = false)
	private String status;

	@Column(name = "transaction_date", columnDefinition = "TIMESTAMPTZ")
	private Instant transactionDate;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "package_id")
	private SubscriptionPackage pkg;

	// --- Constructors ---

	public PaymentTransaction() {
	}

	public PaymentTransaction(Long id, AppUser client, BigDecimal amount, String status, Instant transactionDate) {
		this.id = id;
		this.client = client;
		this.amount = amount;
		this.status = status;
		this.transactionDate = transactionDate;
	}

	public PaymentTransaction(Long id, AppUser client, SubscriptionPackage pkg, BigDecimal amount, String status,
			Instant transactionDate) {
		this.id = id;
		this.client = client;
		this.pkg = pkg;
		this.amount = amount;
		this.status = status;
		this.transactionDate = transactionDate;
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

	public BigDecimal getAmount() {
		return amount;
	}

	public void setAmount(BigDecimal amount) {
		this.amount = amount;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Instant getTransactionDate() {
		return transactionDate;
	}

	public void setTransactionDate(Instant transactionDate) {
		this.transactionDate = transactionDate;
	}

	public SubscriptionPackage getPkg() {
		return pkg;
	}

	public void setPkg(SubscriptionPackage pkg) {
		this.pkg = pkg;
	}

}
