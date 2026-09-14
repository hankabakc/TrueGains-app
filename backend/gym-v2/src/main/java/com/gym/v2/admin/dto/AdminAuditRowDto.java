package com.gym.v2.admin.dto;

import java.time.Instant;

/** Denetim defterinde bir satir. */
public record AdminAuditRowDto(Long id, String action, String userEmail, String ipAddress, String details,
		Instant createdAt) {
}
