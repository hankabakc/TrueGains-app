package com.gym.v2.admin.dto;

import java.math.BigDecimal;
import java.time.Instant;

/** Odeme listesinde bir satir. */
public record AdminPaymentRowDto(Long id, String clientEmail, BigDecimal amount, String status, Instant transactionDate,
		String packageName) {
}
