package com.gym.v2.finance.dto;

import com.gym.v2.finance.entity.OrderStatus;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * Sipariş Bilgileri Transfer Nesnesi (OrderDTO Record)
 */
public record OrderDTO(Long id, Long clientId, Long packageId, String packageName, BigDecimal amount,
		OrderStatus status, String checkoutSessionId, Instant createdAt) {
}
