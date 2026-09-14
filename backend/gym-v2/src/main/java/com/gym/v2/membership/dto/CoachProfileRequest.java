package com.gym.v2.membership.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

/**
 * Antrenör profili güncelleme isteği DTO'su.
 */
public record CoachProfileRequest(
		@NotBlank(message = "{validation.profile.fullName.notBlank}") @Size(max = 100,
				message = "{validation.profile.fullName.size}") String fullName,

		@NotBlank(message = "{validation.profile.bio.notBlank}") @Size(max = 1000,
				message = "{validation.profile.bio.size}") String bio,

		@NotBlank(message = "{validation.profile.specialization.notBlank}") String specialization,

		@NotBlank(message = "{validation.profile.photo.notBlank}") @Size(max = 500,
				message = "{validation.profile.photo.size}") String profilePhotoUrl,
		@Size(max = 500, message = "{validation.instagram.size}") String instagramUrl,
		@Size(max = 500, message = "{validation.website.size}") String websiteUrl,
		@Size(max = 500, message = "{validation.profile.tiktok.size}") String tiktokUrl,

		@Min(value = 50, message = "{validation.profile.height.min}") @Max(value = 250,
				message = "{validation.profile.height.max}") Integer heightCm,

		@DecimalMin(value = "30", message = "{validation.profile.weight.min}") @DecimalMax(value = "300",
				message = "{validation.profile.weight.max}") BigDecimal weightKg,

		@Min(value = 0, message = "Deneyim 0-80 yıl aralığında olmalıdır.") @Max(value = 80,
				message = "Deneyim 0-80 yıl aralığında olmalıdır.") Integer experienceYears,

		@Size(max = 50, message = "İl en fazla 50 karakter olabilir.") String province,

		@Size(max = 50, message = "İlçe en fazla 50 karakter olabilir.") String district) {

	// Manuel getter because user rule: Lombok YASAK, Getter/Setter manuel
	public String getProvince() {
		return province;
	}

	public String getDistrict() {
		return district;
	}

	public String getFullName() {
		return fullName;
	}

	public String getBio() {
		return bio;
	}

	public String getSpecialization() {
		return specialization;
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

	public Integer getExperienceYears() {
		return experienceYears;
	}

}
