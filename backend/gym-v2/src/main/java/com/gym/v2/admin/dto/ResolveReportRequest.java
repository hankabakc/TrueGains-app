package com.gym.v2.admin.dto;

import com.gym.v2.social.entity.ReportStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Sikayeti karara baglama istegi.
 *
 * @param decision {@code ACTIONED} veya {@code DISMISSED}
 * @param note kararin gerekcesi; denetim icin serbest metin
 * @param suspendReportedUser true ise şikâyet edilen hesap aynı işlemde pasifleştirilir;
 * yalnızca ACTIONED kararıyla birlikte kullanılabilir; gönderilmezse null gelir, false
 * olarak yorumlanır
 */
public record ResolveReportRequest(@NotNull(message = "Karar zorunludur.") ReportStatus decision,
		@Size(max = 1000, message = "Not en fazla 1000 karakter olabilir.") String note, Boolean suspendReportedUser) {
}
