package com.gym.v2.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.persistence.Convert;
import com.gym.v2.core.security.EncryptionConverter;
import java.math.BigDecimal;

@Entity
@Table(name = "coach")
public class CoachEntity {

	@Id
	@Column(name = "user_id")
	private Long userId;

	@OneToOne(fetch = FetchType.LAZY)
	@MapsId
	@JoinColumn(name = "user_id")
	private AppUser user;

	@Convert(converter = EncryptionConverter.class)
	@Column(name = "full_name", nullable = false)
	private String fullName;

	@Convert(converter = EncryptionConverter.class)
	@Column(columnDefinition = "TEXT")
	private String bio;

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	private String specialization;

	@Column(length = 10)
	private String currency;

	@Column(name = "profile_photo_url", length = 500)
	private String profilePhotoUrl;

	@Column(name = "instagram_url", length = 500)
	private String instagramUrl;

	@Column(name = "website_url", length = 500)
	private String websiteUrl;

	@Column(name = "tiktok_url", length = 500)
	private String tiktokUrl;

	@Column(name = "height_cm")
	private Integer heightCm;

	@Column(name = "weight_kg")
	private BigDecimal weightKg;

	@Column(name = "show_subscriber_count")
	private Boolean showSubscriberCount = false;

	@Column(name = "max_clients")
	private Integer maxClients;

	// Koçun mesleki deneyim süresi (yıl olarak)
	@Column(name = "experience_years")
	private Integer experienceYears;

	@Column(name = "province", length = 50)
	private String province;

	@Column(name = "district", length = 50)
	private String district;

	// Getters
	public String getProvince() {
		return province;
	}

	public String getDistrict() {
		return district;
	}

	// Setters
	public void setProvince(String province) {
		this.province = province;
	}

	public void setDistrict(String district) {
		this.district = district;
	}

	public String getBio() {
		return bio;
	}

	public String getSpecialization() {
		return specialization;
	}

	public String getCurrency() {
		return currency;
	}

	public String getProfilePhotoUrl() {
		return profilePhotoUrl;
	}

	public String getInstagramUrl() {
		return instagramUrl;
	}

	public String getWebsiteUrl() {
		return websiteUrl;
	}

	public String getTiktokUrl() {
		return tiktokUrl;
	}

	public Integer getHeightCm() {
		return heightCm;
	}

	public BigDecimal getWeightKg() {
		return weightKg;
	}

	public Boolean getShowSubscriberCount() {
		return showSubscriberCount;
	}

	public Integer getExperienceYears() {
		return experienceYears;
	}

	// Setters
	public void setBio(String bio) {
		this.bio = bio;
	}

	public void setSpecialization(String specialization) {
		this.specialization = specialization;
	}

	public void setCurrency(String currency) {
		this.currency = currency;
	}

	public void setProfilePhotoUrl(String profilePhotoUrl) {
		this.profilePhotoUrl = profilePhotoUrl;
	}

	public void setInstagramUrl(String instagramUrl) {
		this.instagramUrl = instagramUrl;
	}

	public void setWebsiteUrl(String websiteUrl) {
		this.websiteUrl = websiteUrl;
	}

	public void setTiktokUrl(String tiktokUrl) {
		this.tiktokUrl = tiktokUrl;
	}

	public void setHeightCm(Integer heightCm) {
		this.heightCm = heightCm;
	}

	public void setWeightKg(BigDecimal weightKg) {
		this.weightKg = weightKg;
	}

	public void setShowSubscriberCount(Boolean showSubscriberCount) {
		this.showSubscriberCount = showSubscriberCount;
	}

	public Integer getMaxClients() {
		return maxClients != null ? maxClients : 10;
	}

	public void setMaxClients(Integer maxClients) {
		this.maxClients = maxClients;
	}

	public void setExperienceYears(Integer experienceYears) {
		this.experienceYears = experienceYears;
	}

	public CoachEntity() {
	}

	public CoachEntity(Long userId) {
		this.userId = userId;
	}

	public Long getUserId() {
		return userId;
	}

	public void setUserId(Long userId) {
		this.userId = userId;
	}

	public AppUser getUser() {
		return user;
	}

	public void setUser(AppUser user) {
		this.user = user;
	}

}
