package com.gym.v2.social.dto;

import com.gym.v2.auth.entity.UserRole;

/**
 * Keşfet (Discovery) modülü için kullanıcı özet verilerini taşıyan DTO.
 */
public record DiscoveryUserDto(Long userId, String fullName, String bio, String profilePhotoUrl, UserRole role,
		String specialization, String currency, boolean canSendRequest) {
}
