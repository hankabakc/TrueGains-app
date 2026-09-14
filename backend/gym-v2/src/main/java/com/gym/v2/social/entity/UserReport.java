package com.gym.v2.social.entity;

import com.gym.v2.core.security.EncryptionConverter;
import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Bir kullanicinin baska bir kullaniciyi sikayeti.
 * <p>
 * {@code user_block}'tan farki: engelleme kisisel bir tercihtir, yoneticiye bildirilmez.
 * Sikayet ise yonetimin gormesi ve KARARA BAGLAMASI gereken kayittir.
 * </p>
 */
@Entity
@Table(name = "user_report")
public class UserReport {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "reporter_id", nullable = false)
	private Long reporterId;

	@Column(name = "reported_user_id", nullable = false)
	private Long reportedUserId;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 40)
	private ReportReason reason;

	/** Kullanicinin serbest yazdigi metin - ucuncu kisiler hakkinda veri icerebilir. */
	@Convert(converter = EncryptionConverter.class)
	@Column(columnDefinition = "TEXT")
	private String description;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private ReportStatus status = ReportStatus.PENDING;

	@Column(name = "created_at", nullable = false)
	private Instant createdAt;

	@Column(name = "reviewed_at")
	private Instant reviewedAt;

	@Column(name = "reviewed_by")
	private String reviewedBy;

	@Column(name = "resolution_note", columnDefinition = "TEXT")
	private String resolutionNote;

	protected UserReport() {
		// JPA
	}

	public UserReport(Long reporterId, Long reportedUserId, ReportReason reason, String description,
			Instant createdAt) {
		this.reporterId = reporterId;
		this.reportedUserId = reportedUserId;
		this.reason = reason;
		this.description = description;
		this.createdAt = createdAt;
	}

	public Long getId() {
		return id;
	}

	public Long getReporterId() {
		return reporterId;
	}

	public Long getReportedUserId() {
		return reportedUserId;
	}

	public ReportReason getReason() {
		return reason;
	}

	public String getDescription() {
		return description;
	}

	public ReportStatus getStatus() {
		return status;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getReviewedAt() {
		return reviewedAt;
	}

	public String getReviewedBy() {
		return reviewedBy;
	}

	public String getResolutionNote() {
		return resolutionNote;
	}

	/** Karara baglar. Durum, karar veren ve zamani birlikte degisir. */
	public void resolve(ReportStatus decision, String adminEmail, String note, Instant at) {
		this.status = decision;
		this.reviewedBy = adminEmail;
		this.resolutionNote = note;
		this.reviewedAt = at;
	}

}
