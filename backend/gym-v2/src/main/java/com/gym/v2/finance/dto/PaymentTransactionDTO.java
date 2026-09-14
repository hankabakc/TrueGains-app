package com.gym.v2.finance.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Ödeme Hareketleri ve Sepet Öğeleri için DTO Record yapısı.
 */
public record PaymentTransactionDTO(Long id, Long packageId, String packageName, Integer durationDays,
		BigDecimal amount, String status, Instant transactionDate) {

}
