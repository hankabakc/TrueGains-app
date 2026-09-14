package com.gym.v2.core.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Sistemdeki güvenlik olaylarını ve kritik işlemleri takip eder. Güvenlik iyileştirmeleri
 * (TIMESTAMPTZ ve doğru zaman yönetimi) içerir.
 */
@Entity
@Table(name = "audit_log", indexes = { @Index(name = "idx_audit_log_email", columnList = "user_email"),
		@Index(name = "idx_audit_log_action", columnList = "action") })
public class AuditLog {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false)
	private String action; // LOGIN_SUCCESS, UNAUTHORIZED_ACCESS, DATA_DELETE vb.

	@Column(name = "user_email")
	private String userEmail;

	@Column(name = "ip_address")
	private String ipAddress;

	@Column(columnDefinition = "TEXT")
	private String details;

	@Column(name = "created_at", nullable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	/**
	 * Varsayılan yapılandırıcı. JPA gereksinimi için eklenmiştir. Dışarıdan izinsiz nesne
	 * üretimini engellemek için protected yapılmıştır.
	 */
	protected AuditLog() {
		// Bulgu #7: Zaman damgası üretimi constructor içinden kaldırıldı.
	}

	/**
	 * Yeni bir audit log kaydı oluşturur.
	 * @param action İşlem türü
	 * @param userEmail İlgili kullanıcı e-postası
	 * @param ipAddress IP adresi
	 * @param details İşlem detayları
	 * @param createdAt İşlem zamanı (Clock üzerinden enjekte edilmelidir)
	 */
	public AuditLog(String action, String userEmail, String ipAddress, String details, Instant createdAt) {
		this.action = action;
		this.userEmail = userEmail;
		this.ipAddress = ipAddress;
		this.details = details;
		this.createdAt = createdAt;
	}

	// Getters
	public Long getId() {
		return id;
	}

	public String getAction() {
		return action;
	}

	public String getUserEmail() {
		return userEmail;
	}

	public String getIpAddress() {
		return ipAddress;
	}

	public String getDetails() {
		return details;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

}
