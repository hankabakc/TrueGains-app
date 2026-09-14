package com.gym.v2.social.dto;

import java.time.Instant;

public record ClientGalleryDto(Long id, String imageUrl, Instant createdAt) {
}
