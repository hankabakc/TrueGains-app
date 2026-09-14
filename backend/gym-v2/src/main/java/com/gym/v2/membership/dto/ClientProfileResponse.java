package com.gym.v2.membership.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Kullanıcı profil bilgilerini dönen DTO (Record).
 */
public record ClientProfileResponse(Long userId, String fullName, String email, String profilePhotoUrl,
		LocalDate dateOfBirth, String gender, Integer heightCm, BigDecimal weightKg, String goal, String activityLevel,
		String bio, String instagramUrl, String websiteUrl, String tiktokUrl, List<String> publicPhotos,
		Boolean showAge, Boolean showHeight, Boolean showWeight, String province, String district,
		String experienceLevel) {
}
