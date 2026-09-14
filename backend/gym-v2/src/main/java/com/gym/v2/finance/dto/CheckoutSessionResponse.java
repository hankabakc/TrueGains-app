package com.gym.v2.finance.dto;

/**
 * Ödeme Sağlayıcı Oturumu DTO (CheckoutSessionResponse Record)
 */
public record CheckoutSessionResponse(String checkoutSessionId, String paymentUrl) {
}
