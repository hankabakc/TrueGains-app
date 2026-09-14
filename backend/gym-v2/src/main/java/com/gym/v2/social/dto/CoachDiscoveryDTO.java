package com.gym.v2.social.dto;

import java.math.BigDecimal;

public record CoachDiscoveryDTO(Long userId, String fullName, String bio, String specialization, String currency,
		String profilePhotoUrl, String instagramUrl, Double averageRating, Integer reviewCount,
		Integer activeStudentCount, String province, String district, Integer experienceYears,
		BigDecimal minPackagePrice) {
}
