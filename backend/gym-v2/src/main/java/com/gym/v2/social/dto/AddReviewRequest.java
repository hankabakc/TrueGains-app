package com.gym.v2.social.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Antrenör değerlendirme isteği (Review) için kullanılan veri taşıma nesnesi.
 * <p>
 * Bu sınıf; puan (rating) ve yorum (comment) bilgilerini taşır ve validasyon kurallarını
 * uygular.
 * </p>
 */
public record AddReviewRequest(
		@NotNull(message = "Puan alanı boş bırakılamaz.") @Min(value = 1, message = "Puan en az 1 olabilir.") @Max(
				value = 5, message = "Puan en fazla 5 olabilir.") Integer rating,

		@Size(max = 1000, message = "Yorum en fazla 1000 karakter olabilir.") String comment) {
}
