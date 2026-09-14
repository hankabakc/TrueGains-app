package com.gym.v2.social.dto;

import java.time.Instant;

public record CoachReviewDto(Long id, Long clientId, String clientName, Integer rating, String comment,
		Instant createdAt, String packageName) {
}
