package com.gym.v2.social.dto;

import com.gym.v2.social.entity.PairingStatus;
import java.time.Instant;

/**
 * Eşleşme İsteği DTO (PairingRequestDTO) Bulgu #1: Zaman damgaları Instant tipine
 * çekildi.
 */
public record PairingRequestDTO(Long id, Long clientId, String clientName, Long coachId, String coachName,
		PairingStatus status, String message, Instant createdAt, Instant updatedAt) {
}
