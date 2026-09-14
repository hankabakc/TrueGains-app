package com.gym.v2.admin.dto;

import java.math.BigDecimal;

/** {@code AdminFinanceRepository.listPayments} satir projeksiyonu. */
public interface AdminPaymentRowProjection {

	Long getId();

	String getClientEmail();

	BigDecimal getAmount();

	String getStatus();

	Object getTransactionDate();

	String getPackageName();

}
