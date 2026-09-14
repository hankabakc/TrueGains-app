package com.gym.v2.admin.dto;

import java.util.List;

/**
 * Hata ve cokme ozeti.
 *
 * @param configured Sentry yapilandirilmis mi. false ise liste bos gelir ve panel
 * "yapilandirilmamis" der - hata gibi gostermez
 * @param message yapilandirma ya da erisim sorunu varsa aciklamasi
 * @param backendIssues backend acik sorun sayisi
 * @param mobileIssues mobil acik sorun sayisi
 * @param issues en cok tekrarlayanlar
 */
public record AdminErrorsDto(boolean configured, String message, int backendIssues, int mobileIssues,
		List<AdminIssueDto> issues) {
}
