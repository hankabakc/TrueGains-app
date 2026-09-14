package com.gym.v2.social.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Antrenör galerisine (portfolyo veya başarı resmi) yeni öğe ekleme isteği.
 */
public record AddGalleryItemRequest(
		@NotNull(message = "Resim URL alanı boş bırakılamaz.") @Size(max = 500,
				message = "URL en fazla 500 karakter olmalıdır.") @Pattern(
						regexp = "^(https?://)(?:[a-zA-Z0-9.-]+)(?::\\d+)?(?:/[^<>\\s]*)?$",
						message = "Geçersiz resim URL formatı.") String imageUrl,

		Boolean isStudentProgress) {
}
