package com.gym.v2.social.dto;

import java.time.Instant;

public record MessageDTO(Long id, Long conversationId, Long senderId, String senderFullName, String content,
		String status, String attachmentUrl, Instant sentAt, Long packageId, String packageName,
		java.math.BigDecimal packagePrice) {
}
