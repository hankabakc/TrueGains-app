package com.gym.v2.social.entity;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.security.EncryptionConverter;
import jakarta.persistence.*;
import java.time.Instant;

/**
 * Sohbet mesajı. Bulgu #2: Zaman yönetimi ve TIMESTAMPTZ geçişi yapıldı.
 */
@Entity
@Table(name = "message")
public class Message {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "conversation_id", nullable = false)
	private Conversation conversation;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "sender_id", nullable = false)
	private AppUser sender;

	@Convert(converter = EncryptionConverter.class)
	@Column(nullable = true, columnDefinition = "TEXT")
	private String content;

	@Enumerated(EnumType.STRING)
	@Column(name = "status", nullable = false)
	private MessageStatus status = MessageStatus.SENT;

	@Column(name = "attachment_url", length = 1024)
	private String attachmentUrl;

	@Column(name = "sent_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant sentAt;

	@Column(name = "is_blocked_delivery", nullable = false)
	private boolean blockedDelivery = false;

	public Message() {
	}

	/**
	 * Gönderim anını set eder.
	 */
	public void onPersist(Instant now) {
		this.sentAt = now;
	}

	// Manual Getters and Setters
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Conversation getConversation() {
		return conversation;
	}

	public void setConversation(Conversation conversation) {
		this.conversation = conversation;
	}

	public AppUser getSender() {
		return sender;
	}

	public void setSender(AppUser sender) {
		this.sender = sender;
	}

	public String getContent() {
		return content;
	}

	public void setContent(String content) {
		this.content = content;
	}

	public MessageStatus getStatus() {
		return status;
	}

	public void setStatus(MessageStatus status) {
		this.status = status;
	}

	public String getAttachmentUrl() {
		return attachmentUrl;
	}

	public void setAttachmentUrl(String attachmentUrl) {
		this.attachmentUrl = attachmentUrl;
	}

	public Instant getSentAt() {
		return sentAt;
	}

	public boolean isBlockedDelivery() {
		return blockedDelivery;
	}

	public void setBlockedDelivery(boolean blockedDelivery) {
		this.blockedDelivery = blockedDelivery;
	}

	@Column(name = "package_id")
	private Long packageId;

	@Column(name = "package_name", length = 255)
	private String packageName;

	@Column(name = "package_price")
	private java.math.BigDecimal packagePrice;

	public Long getPackageId() {
		return packageId;
	}

	public void setPackageId(Long packageId) {
		this.packageId = packageId;
	}

	public String getPackageName() {
		return packageName;
	}

	public void setPackageName(String packageName) {
		this.packageName = packageName;
	}

	public java.math.BigDecimal getPackagePrice() {
		return packagePrice;
	}

	public void setPackagePrice(java.math.BigDecimal packagePrice) {
		this.packagePrice = packagePrice;
	}

}
