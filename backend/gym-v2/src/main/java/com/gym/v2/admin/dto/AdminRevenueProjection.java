package com.gym.v2.admin.dto;

import java.math.BigDecimal;

/** {@code AdminFinanceRepository.loadSummary} tek satirlik sonucu. */
public interface AdminRevenueProjection {

	BigDecimal getRevenueToday();

	BigDecimal getRevenue7d();

	BigDecimal getRevenue30d();

	BigDecimal getRevenueTotal();

	long getSuccessfulPayments();

	long getFailedPayments();

	long getActiveSubscriptions();

	long getExpiringIn7d();

}
