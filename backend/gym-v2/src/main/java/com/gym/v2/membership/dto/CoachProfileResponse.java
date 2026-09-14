package com.gym.v2.membership.dto;

import java.math.BigDecimal;

/**
 * Koç profil bilgilerini dönen DTO (Record).
 */
public record CoachProfileResponse(Long userId, String fullName, String email, String profilePhotoUrl, String bio,
		String specialization, String instagramUrl, String websiteUrl, String tiktokUrl, Integer heightCm,
		BigDecimal weightKg, Integer maxClients) {
}
