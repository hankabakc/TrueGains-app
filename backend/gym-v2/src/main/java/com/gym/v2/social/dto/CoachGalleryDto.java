package com.gym.v2.social.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;

public record CoachGalleryDto(Long id,

		@Size(max = 500, message = "{validation.url.size}") @Pattern(
				regexp = "^(https?://)(?:[a-zA-Z0-9.-]+)(?::\\d+)?(?:/[^<>\\s]*)?$",
				message = "{validation.url.pattern}") String imageUrl,

		Boolean isStudentProgress, Instant createdAt) {
}
