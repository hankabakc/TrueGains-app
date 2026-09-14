package com.gym.v2.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import com.gym.v2.core.security.EncryptionConverter;
import java.time.Instant;
import java.time.LocalDate;

/**
 * Uygulamanın temel kullanıcı verilerini temsil eden JPA varlık (entity) sınıfı.
 * <p>
 * Bu sınıf; e-posta, şifre, rol ve hesap durumu (aktiflik, kilitlenme vb.) gibi kimlik
 * doğrulama ve yetkilendirme için kritik olan bilgileri saklar.
 * </p>
 *
 * <h2>Yenilikler (Aşama 9):</h2> - **Immutable Identifiers:** id ve registeredAt
 * alanlarının setter metotları güvenlik için sitemden silindi. - **Sealed Builder:** Tüm
 * alanları kapsayan sızdırmaz bir manuel Builder katmanı eklendi. - **Protected
 * No-Args:** Hibernate için gereken boş constructor, dış dünyadan erişimi kapatmak için
 * protected yapıldı. - **Private Builder-Constructor:** Nesne üretimi tamamen Builder
 * üzerinden kilitlendi.
 */
@Entity
@Table(name = "app_user")
public class AppUser {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "external_id", unique = true, nullable = false, length = 36)
	private String externalId;

	@Version
	private Long version;

	@Column(nullable = false, unique = true)
	private String email;

	@Column(nullable = false)
	private String password;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 10)
	private UserRole role; // CLIENT, COACH, ADMIN

	@Column(name = "registered_at", updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant registeredAt;

	@Column(name = "is_active")
	private Boolean isActive;

	@Column(name = "failed_login_attempts")
	private Integer failedLoginAttempts = 0;

	@Column(name = "account_locked_until", columnDefinition = "TIMESTAMPTZ")
	private Instant accountLockedUntil;

	@Column(name = "last_login_at", columnDefinition = "TIMESTAMPTZ")
	private Instant lastLoginAt;

	@Column(name = "is_premium")
	private Boolean isPremium = false;

	@Column(name = "daily_scan_count")
	private Integer dailyScanCount = 0;

	@Column(name = "last_scan_date")
	private LocalDate lastScanDate;

	@Column(name = "daily_ai_recipe_count")
	private Integer dailyAiRecipeCount = 0;

	@Column(name = "last_ai_recipe_date")
	private LocalDate lastAiRecipeDate;

	@Column(name = "last_ai_recipe_suggestion", columnDefinition = "TEXT")
	private String lastAiRecipeSuggestion;

	@Column(name = "profile_photo_url", length = 500)
	private String profilePhotoUrl;

	@Convert(converter = EncryptionConverter.class)
	@Column(name = "phone_number", unique = true)
	private String phoneNumber;

	@Column(name = "is_phone_verified", nullable = false)
	private Boolean isPhoneVerified = false;

	@Column(name = "otp_code", length = 6)
	private String otpCode;

	@Column(name = "otp_expires_at", columnDefinition = "TIMESTAMPTZ")
	private Instant otpExpiresAt;

	@Column(name = "otp_attempt_count")
	private Integer otpAttemptCount = 0;

	@Column(name = "otp_last_sent_at", columnDefinition = "TIMESTAMPTZ")
	private Instant otpLastSentAt;

	@Column(name = "fcm_token")
	private String fcmToken;

	/**
	 * JPA/Hibernate kullanımı için gereken boş yapılandırıcı. Uygulama kodu içinde
	 * yanlışlıkla boş nesne yaratılmasını engellemek için protected yapıldı.
	 */
	protected AppUser() {
	}

	/**
	 * Builder üzerinden nesne oluşturmak için kullanılan özel yapılandırıcı.
	 * @param builder Verileri taşıyan Builder nesnesi.
	 */
	private AppUser(Builder builder) {
		this.version = builder.version;
		this.email = builder.email;
		this.password = builder.password;
		this.role = builder.role;
		this.registeredAt = builder.registeredAt;
		this.isActive = builder.isActive;
		this.failedLoginAttempts = builder.failedLoginAttempts;
		this.accountLockedUntil = builder.accountLockedUntil;
		this.lastLoginAt = builder.lastLoginAt;
		this.isPremium = builder.isPremium;
		this.dailyScanCount = builder.dailyScanCount;
		this.lastScanDate = builder.lastScanDate;
		this.dailyAiRecipeCount = builder.dailyAiRecipeCount;
		this.lastAiRecipeDate = builder.lastAiRecipeDate;
		this.lastAiRecipeSuggestion = builder.lastAiRecipeSuggestion;
		this.profilePhotoUrl = builder.profilePhotoUrl;
		this.externalId = builder.externalId;
		this.phoneNumber = builder.phoneNumber;
		this.isPhoneVerified = builder.isPhoneVerified;
		this.otpCode = builder.otpCode;
		this.otpExpiresAt = builder.otpExpiresAt;
		this.otpLastSentAt = builder.otpLastSentAt;
		this.fcmToken = builder.fcmToken;
	}

	// Getters
	public Long getId() {
		return id;
	}

	public String getExternalId() {
		return externalId;
	}

	public Long getVersion() {
		return version;
	}

	public String getEmail() {
		return email;
	}

	public String getPassword() {
		return password;
	}

	public UserRole getRole() {
		return role;
	}

	public Instant getRegisteredAt() {
		return registeredAt;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public Integer getFailedLoginAttempts() {
		return failedLoginAttempts;
	}

	public Instant getAccountLockedUntil() {
		return accountLockedUntil;
	}

	public Instant getLastLoginAt() {
		return lastLoginAt;
	}

	public Boolean getIsPremium() {
		return isPremium;
	}

	public Integer getDailyScanCount() {
		return dailyScanCount;
	}

	public LocalDate getLastScanDate() {
		return lastScanDate;
	}

	public Integer getDailyAiRecipeCount() {
		return dailyAiRecipeCount;
	}

	public LocalDate getLastAiRecipeDate() {
		return lastAiRecipeDate;
	}

	public String getLastAiRecipeSuggestion() {
		return lastAiRecipeSuggestion;
	}

	public String getProfilePhotoUrl() {
		return profilePhotoUrl;
	}

	public String getPhoneNumber() {
		return phoneNumber;
	}

	public Boolean getIsPhoneVerified() {
		return isPhoneVerified;
	}

	public String getOtpCode() {
		return otpCode;
	}

	public Instant getOtpExpiresAt() {
		return otpExpiresAt;
	}

	public Integer getOtpAttemptCount() {
		return otpAttemptCount;
	}

	public Instant getOtpLastSentAt() {
		return otpLastSentAt;
	}

	public String getFcmToken() {
		return fcmToken;
	}

	// Setters (Immutable alanlar (id, registeredAt) için setter SİLİNDİ)
	public void setVersion(Long version) {
		this.version = version;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public void setRole(UserRole role) {
		this.role = role;
	}

	public void setIsActive(Boolean isActive) {
		this.isActive = isActive;
	}

	public void setFailedLoginAttempts(Integer attempts) {
		this.failedLoginAttempts = attempts;
	}

	public void setAccountLockedUntil(Instant until) {
		this.accountLockedUntil = until;
	}

	public void setLastLoginAt(Instant at) {
		this.lastLoginAt = at;
	}

	public void setIsPremium(Boolean isPremium) {
		this.isPremium = isPremium;
	}

	public void setDailyScanCount(Integer count) {
		this.dailyScanCount = count;
	}

	public void setLastScanDate(LocalDate date) {
		this.lastScanDate = date;
	}

	public void setDailyAiRecipeCount(Integer count) {
		this.dailyAiRecipeCount = count;
	}

	public void setLastAiRecipeDate(LocalDate date) {
		this.lastAiRecipeDate = date;
	}

	public void setLastAiRecipeSuggestion(String suggestion) {
		this.lastAiRecipeSuggestion = suggestion;
	}

	public void setProfilePhotoUrl(String profilePhotoUrl) {
		this.profilePhotoUrl = profilePhotoUrl;
	}

	public void setPhoneNumber(String phoneNumber) {
		this.phoneNumber = phoneNumber;
	}

	public void setIsPhoneVerified(Boolean isPhoneVerified) {
		this.isPhoneVerified = isPhoneVerified;
	}

	public void setOtpCode(String otpCode) {
		this.otpCode = otpCode;
	}

	public void setOtpExpiresAt(Instant otpExpiresAt) {
		this.otpExpiresAt = otpExpiresAt;
	}

	public void setOtpAttemptCount(Integer otpAttemptCount) {
		this.otpAttemptCount = otpAttemptCount;
	}

	public void setOtpLastSentAt(Instant otpLastSentAt) {
		this.otpLastSentAt = otpLastSentAt;
	}

	public void setFcmToken(String fcmToken) {
		this.fcmToken = fcmToken;
	}

	/**
	 * AppUser nesneleri için sızdırmaz Builder sınıfı.
	 */
	public static class Builder {

		private Long version;

		private String email;

		private String password;

		private UserRole role;

		private Instant registeredAt;

		private Boolean isActive = true;

		private Integer failedLoginAttempts = 0;

		private Instant accountLockedUntil;

		private Instant lastLoginAt;

		private Boolean isPremium = false;

		private Integer dailyScanCount = 0;

		private LocalDate lastScanDate;

		private Integer dailyAiRecipeCount = 0;

		private LocalDate lastAiRecipeDate;

		private String lastAiRecipeSuggestion;

		private String profilePhotoUrl;

		private String externalId = java.util.UUID.randomUUID().toString();

		private String phoneNumber;

		private Boolean isPhoneVerified = false;

		private String otpCode;

		private Instant otpExpiresAt;

		private Instant otpLastSentAt;

		private String fcmToken;

		public Builder version(Long pVersion) {
			this.version = pVersion;
			return this;
		}

		public Builder email(String pEmail) {
			this.email = pEmail;
			return this;
		}

		public Builder password(String pPassword) {
			this.password = pPassword;
			return this;
		}

		public Builder role(UserRole pRole) {
			this.role = pRole;
			return this;
		}

		public Builder registeredAt(Instant pRegisteredAt) {
			this.registeredAt = pRegisteredAt;
			return this;
		}

		public Builder isActive(Boolean pIsActive) {
			this.isActive = pIsActive;
			return this;
		}

		public Builder failedLoginAttempts(Integer pAttempts) {
			this.failedLoginAttempts = pAttempts;
			return this;
		}

		public Builder accountLockedUntil(Instant pUntil) {
			this.accountLockedUntil = pUntil;
			return this;
		}

		public Builder lastLoginAt(Instant pAt) {
			this.lastLoginAt = pAt;
			return this;
		}

		public Builder isPremium(Boolean pIsPremium) {
			this.isPremium = pIsPremium;
			return this;
		}

		public Builder dailyScanCount(Integer pCount) {
			this.dailyScanCount = pCount;
			return this;
		}

		public Builder lastScanDate(LocalDate pDate) {
			this.lastScanDate = pDate;
			return this;
		}

		public Builder dailyAiRecipeCount(Integer pCount) {
			this.dailyAiRecipeCount = pCount;
			return this;
		}

		public Builder lastAiRecipeDate(LocalDate pDate) {
			this.lastAiRecipeDate = pDate;
			return this;
		}

		public Builder lastAiRecipeSuggestion(String pSuggestion) {
			this.lastAiRecipeSuggestion = pSuggestion;
			return this;
		}

		public Builder profilePhotoUrl(String pProfilePhotoUrl) {
			this.profilePhotoUrl = pProfilePhotoUrl;
			return this;
		}

		public Builder externalId(String pExternalId) {
			this.externalId = pExternalId;
			return this;
		}

		public Builder phoneNumber(String pPhoneNumber) {
			this.phoneNumber = pPhoneNumber;
			return this;
		}

		public Builder isPhoneVerified(Boolean pIsPhoneVerified) {
			this.isPhoneVerified = pIsPhoneVerified;
			return this;
		}

		public Builder otpCode(String pOtpCode) {
			this.otpCode = pOtpCode;
			return this;
		}

		public Builder otpExpiresAt(Instant pOtpExpiresAt) {
			this.otpExpiresAt = pOtpExpiresAt;
			return this;
		}

		public Builder otpLastSentAt(Instant pOtpLastSentAt) {
			this.otpLastSentAt = pOtpLastSentAt;
			return this;
		}

		public Builder fcmToken(String pFcmToken) {
			this.fcmToken = pFcmToken;
			return this;
		}

		public AppUser build() {
			return new AppUser(this);
		}

	}

	public static Builder builder() {
		return new Builder();
	}

}
