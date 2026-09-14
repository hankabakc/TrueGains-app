package com.gym.v2.membership.dto;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Sporcu profili güncelleme isteği DTO'su.
 */
public record ClientProfileRequest(
		@NotBlank(message = "{validation.profile.fullName.notBlank}") @Size(max = 100,
				message = "{validation.profile.fullName.size}") String fullName,

		@Past(message = "{validation.profile.dateOfBirth.past}") LocalDate dateOfBirth,

		String gender,

		@NotNull(message = "{validation.profile.height.notNull}") @Min(value = 50,
				message = "{validation.profile.height.min}") @Max(value = 250,
						message = "{validation.profile.height.max}") Integer heightCm,

		@NotNull(message = "{validation.profile.weight.notNull}") @DecimalMin(value = "30",
				message = "{validation.profile.weight.min}") @DecimalMax(value = "300",
						message = "{validation.profile.weight.max}") BigDecimal weightKg,

		String goal,

		String activityLevel,

		@NotBlank(message = "{validation.profile.bio.notBlank}") @Size(max = 500,
				message = "{validation.profile.bio.size}") String bio,

		@NotBlank(message = "{validation.profile.photo.notBlank}") @Size(max = 500,
				message = "{validation.profile.photo.size}") String profilePhotoUrl,
		@Size(max = 255, message = "{validation.instagram.size}") String instagramUrl,
		@Size(max = 255, message = "{validation.website.size}") String websiteUrl,
		@Size(max = 500, message = "{validation.profile.tiktok.size}") String tiktokUrl,
		// Tek alan sinirsizdi: istek govdesi sinirina kadar (20MB) satir yazilabiliyordu
		// ve
		// koleksiyon EAGER oldugu icin bu sporcunun kaydini yukleyen HER ekran hepsini
		// cekiyordu.
		@Size(max = 20,
				message = "En fazla 20 fotograf eklenebilir.") List<@Size(max = 500,
						message = "Fotograf adresi en fazla 500 karakter olabilir.") String> publicPhotos,
		boolean showAge, boolean showHeight, boolean showWeight,
		@Size(max = 50, message = "İl en fazla 50 karakter olabilir.") String province,
		@Size(max = 50, message = "İlçe en fazla 50 karakter olabilir.") String district,
		@Size(max = 20, message = "Deneyim seviyesi en fazla 20 karakter olabilir.") String experienceLevel) {
}
