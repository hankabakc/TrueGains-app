package com.gym.v2.social.dto;

import com.gym.v2.social.entity.ReportReason;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Uygulamadan gelen sikayet istegi.
 *
 * @param reportedUserId sikayet edilen kullanici
 * @param reason kapali kumeden bir sebep
 * @param description istege bagli aciklama; sifreli saklanir
 */
public record CreateReportRequest(@NotNull(message = "Şikâyet edilen kullanıcı zorunludur.") Long reportedUserId,
		@NotNull(message = "Sebep zorunludur.") ReportReason reason,
		@Size(max = 1000, message = "Açıklama en fazla 1000 karakter olabilir.") String description) {
}
