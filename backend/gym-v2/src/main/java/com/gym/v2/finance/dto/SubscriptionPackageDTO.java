package com.gym.v2.finance.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record SubscriptionPackageDTO(Long id, @NotBlank(message = "Paket adı boş bırakılamaz.") String name,
		@NotNull(message = "Fiyat alanı zorunludur.") @DecimalMin(value = "0.01",
				message = "Fiyat en az 0.01 ₺ olmalıdır.") BigDecimal price,
		@NotNull(message = "Süre alanı zorunludur.") @Min(value = 1,
				message = "Süre en az 1 gün olmalıdır.") Integer durationDays,
		Long coachId, @NotBlank(message = "Açıklama zorunludur.") String description,
		@NotBlank(message = "Neler dahil olduğu zorunludur.") String features,
		@Min(value = 1, message = "Kontenjan en az 1 olmalıdır.") Integer quota, Integer activeSubscriberCount,
		@NotBlank(message = "Paket seviyesi seçilmelidir.") String levels,
		@NotBlank(message = "Çalışma modu seçilmelidir.") String mode) {
}
