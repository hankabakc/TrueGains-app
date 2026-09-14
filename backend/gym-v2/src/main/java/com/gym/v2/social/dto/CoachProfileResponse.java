package com.gym.v2.social.dto;

import java.math.BigDecimal;
import java.util.List;

public record CoachProfileResponse(Long coachId, String fullName, String profilePhotoUrl, String bio,
		String specialization, String currency, String subscriberCountTier, Boolean isSubscribed, String instagramUrl,
		String tiktokUrl, Integer heightCm, BigDecimal weightKg, List<CoachGalleryDto> portfolioImages,
		List<CoachGalleryDto> studentProgressImages, List<CoachStudentProgressDto> authorizedStudentProgress,
		Double averageRating, Integer reviewCount, Integer activeStudentCount, java.time.Instant memberSince,
		Integer experienceYears, String province, String district) {
}
