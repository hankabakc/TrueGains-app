package com.gym.v2.social.dto;

import java.time.Instant;

public record CoachStudentProgressDto(Long id, Long coachId, Long clientId, String studentNickname,
		String beforeImageUrl, String afterImageUrl, String description, String status, Instant createdAt) {
}
