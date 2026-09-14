package com.gym.v2.measurement.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * GYMAPP-V2 Ölçüm DTO'su (Immutable Record). Frontend ile veri alışverişinde kullanılır.
 */
@Schema(description = "Vücut Ölçüm Veri Transfer Nesnesi")
public record MeasurementDTO(

		@Schema(description = "Ölçüm ID (Yeni kayıtta veya güncellemede sistem tarafından yönetilir)",
				example = "1") Long id,

		@Schema(description = "Kilo (kg)",
				example = "75.5") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal weight,

		@Schema(description = "Boy (cm)",
				example = "175.5") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal height,

		@Schema(description = "Yağ oranı (%)", example = "15.2") @DecimalMin(value = "0.0", inclusive = false,
				message = "Yağ oranı 0'dan büyük olmalıdır") @DecimalMax(value = "100.0",
						message = "Yağ oranı 100'den büyük olamaz") @Positive(
								message = "Ölçüm değeri pozitif olmalıdır") BigDecimal bodyFatPct,

		@Schema(description = "Kas Kütlesi (kg)",
				example = "35.5") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal muscleMass,

		@Schema(description = "Göğüs çevresi (cm)",
				example = "102.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal chest,

		@Schema(description = "Bel çevresi (cm)",
				example = "85.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal waist,

		@Schema(description = "Omuz çevresi (cm)",
				example = "120.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal shoulders,

		@Schema(description = "Sol kol çevresi (cm)",
				example = "38.5") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal leftArm,

		@Schema(description = "Sağ kol çevresi (cm)",
				example = "39.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal rightArm,

		@Schema(description = "Sol bacak çevresi (cm)",
				example = "60.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal leftLeg,

		@Schema(description = "Sağ bacak çevresi (cm)",
				example = "60.5") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal rightLeg,

		@Schema(description = "Kalça çevresi (cm)",
				example = "98.0") @Positive(message = "Ölçüm değeri pozitif olmalıdır") BigDecimal hips,

		@Schema(description = "Kullanıcı notları", example = "Antrenman sonrası ölçüm alındı.") @Size(max = 500,
				message = "Not en fazla 500 karakter olabilir") String notes,

		@Schema(description = "Ölçüm tarihi", example = "2026-03-31T14:30:00Z") @PastOrPresent(
				message = "Ölçüm tarihi gelecekte olamaz") Instant createdAt,

		@Schema(description = "Antrenörle paylaşılma durumu", example = "false") Boolean isSharedWithCoach) {
}
