package com.gym.v2.social.dto;

import java.time.Instant;

public record ConversationDTO(Long id, Long clientId, String clientFullName, Long coachId, String coachFullName,
		Instant lastMessageAt, String lastMessagePreview, Integer unreadCount, Boolean isActive) {
}
