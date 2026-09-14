package com.gym.v2.admin.dto;

import java.math.BigDecimal;

/**
 * Gelir ozeti. Yalnizca {@code SUCCESS} durumundaki islemler sayilir; basarisiz denemeler
 * ciroya girmemeli ama ayri bir sayaci var (odeme saglayicisinda sorun varsa ilk belirti
 * odur).
 */
public record AdminRevenueDto(BigDecimal revenueToday, BigDecimal revenue7d, BigDecimal revenue30d,
		BigDecimal revenueTotal, long successfulPayments, long failedPayments, long activeSubscriptions,
		long expiringIn7d) {
}
