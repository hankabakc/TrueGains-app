package com.gym.v2.auth.entity;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import jakarta.persistence.Convert;
import com.gym.v2.core.security.EncryptionConverter;
import java.util.List;

@Entity
@Table(name = "client")
public class ClientEntity {

	@Id
	@Column(name = "user_id")
	private Long userId;

	@OneToOne(fetch = FetchType.LAZY)
	@MapsId
	@JoinColumn(name = "user_id")
	private AppUser user;

	@Column(name = "coach_id")
	private Long coachId;

	@Convert(converter = EncryptionConverter.class)
	@Column(name = "full_name", nullable = false)
	private String fullName;

	@Column(name = "date_of_birth")
	private LocalDate dateOfBirth;

	@Column(length = 50)
	private String gender;

	@Column(name = "height_cm")
	private Integer heightCm;

	@Column(name = "weight_kg")
	private BigDecimal weightKg;

	private String goal;

	@Column(name = "activity_level")
	private String activityLevel;

	@Column(name = "profile_photo_url", length = 500)
	private String profilePhotoUrl;

	@Convert(converter = EncryptionConverter.class)
	@Column(columnDefinition = "TEXT")
	private String bio;

	@Column(name = "instagram_url", length = 255)
	private String instagramUrl;

	@Column(name = "website_url", length = 255)
	private String websiteUrl;

	@Column(name = "tiktok_url", length = 500)
	private String tiktokUrl;

	@ElementCollection(fetch = FetchType.EAGER)
	@CollectionTable(name = "client_public_photo", joinColumns = @JoinColumn(name = "client_id"))
	@Column(name = "photo_url")
	private List<String> publicPhotos = new ArrayList<>();

	// Gizlilik Ayarları (SQL yedeğinden gelen ana fikir)
	@Column(name = "show_age")
	private Boolean showAge = true;

	@Column(name = "show_height")
	private Boolean showHeight = true;

	@Column(name = "show_weight")
	private Boolean showWeight = true;

	@Column(name = "province", length = 50)
	private String province;

	@Column(name = "district", length = 50)
	private String district;

	@Column(name = "experience_level", length = 20)
	private String experienceLevel;

	// Getters and Setters
	public String getProvince() {
		return province;
	}

	public void setProvince(String province) {
		this.province = province;
	}

	public String getDistrict() {
		return district;
	}

	public void setDistrict(String district) {
		this.district = district;
	}

	public String getExperienceLevel() {
		return experienceLevel;
	}

	public void setExperienceLevel(String experienceLevel) {
		this.experienceLevel = experienceLevel;
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

	public Long getCoachId() {
		return coachId;
	}

	public void setCoachId(Long coachId) {
		this.coachId = coachId;
	}

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	public LocalDate getDateOfBirth() {
		return dateOfBirth;
	}

	public void setDateOfBirth(LocalDate dateOfBirth) {
		this.dateOfBirth = dateOfBirth;
	}

	public String getGender() {
		return gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	public Integer getHeightCm() {
		return heightCm;
	}

	public void setHeightCm(Integer heightCm) {
		this.heightCm = heightCm;
	}

	public BigDecimal getWeightKg() {
		return weightKg;
	}

	public void setWeightKg(BigDecimal weightKg) {
		this.weightKg = weightKg;
	}

	public String getGoal() {
		return goal;
	}

	public void setGoal(String goal) {
		this.goal = goal;
	}

	public String getActivityLevel() {
		return activityLevel;
	}

	public void setActivityLevel(String activityLevel) {
		this.activityLevel = activityLevel;
	}

	public String getProfilePhotoUrl() {
		return profilePhotoUrl;
	}

	public void setProfilePhotoUrl(String profilePhotoUrl) {
		this.profilePhotoUrl = profilePhotoUrl;
	}

	public String getBio() {
		return bio;
	}

	public void setBio(String bio) {
		this.bio = bio;
	}

	public String getInstagramUrl() {
		return instagramUrl;
	}

	public void setInstagramUrl(String instagramUrl) {
		this.instagramUrl = instagramUrl;
	}

	public String getWebsiteUrl() {
		return websiteUrl;
	}

	public void setWebsiteUrl(String websiteUrl) {
		this.websiteUrl = websiteUrl;
	}

	public String getTiktokUrl() {
		return tiktokUrl;
	}

	public void setTiktokUrl(String tiktokUrl) {
		this.tiktokUrl = tiktokUrl;
	}

	public Boolean getShowAge() {
		return showAge;
	}

	public void setShowAge(Boolean showAge) {
		this.showAge = showAge;
	}

	public Boolean getShowHeight() {
		return showHeight;
	}

	public void setShowHeight(Boolean showHeight) {
		this.showHeight = showHeight;
	}

	public Boolean getShowWeight() {
		return showWeight;
	}

	public void setShowWeight(Boolean showWeight) {
		this.showWeight = showWeight;
	}

	public List<String> getPublicPhotos() {
		return publicPhotos;
	}

	public void setPublicPhotos(List<String> publicPhotos) {
		this.publicPhotos = publicPhotos;
	}

	public ClientEntity() {
	}

	public ClientEntity(Long userId) {
		this.userId = userId;
	}

}
