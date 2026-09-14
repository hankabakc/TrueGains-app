package com.gym.v2.social.dto;

import com.gym.v2.core.util.FileUrls;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateProgressRequest(@NotNull(message = "Sporcu ID alanı boş bırakılamaz.") Long clientId,

		@NotBlank(message = "Öğrenci rumuzu boş bırakılamaz.") @Size(max = 255,
				message = "Rumuz en fazla 255 karakter olmalıdır.") String studentNickname,

		// Adresler yalnızca kendi dosya ucumuzu gösterebilir ve sunucu adı saklanmadan
		// önce atılır (gerekçe FileUrls'te). Uzunluk sınırı kolonla (VARCHAR(500))
		// hizalı: sınır olmadan uzun adres doğrulamayı geçip veritabanına çarpıyor ve
		// istemciye 400 yerine 500 dönüyordu.
		@NotBlank(message = "Öncesi resmi boş bırakılamaz.") @Size(max = 500,
				message = "{validation.url.size}") @Pattern(regexp = FileUrls.PATTERN,
						message = "{validation.url.pattern}") String beforeImageUrl,

		@NotBlank(message = "Sonrası resmi boş bırakılamaz.") @Size(max = 500,
				message = "{validation.url.size}") @Pattern(regexp = FileUrls.PATTERN,
						message = "{validation.url.pattern}") String afterImageUrl,

		@Size(max = 2000, message = "Açıklama en fazla 2000 karakter olmalıdır.") String description) {
}
