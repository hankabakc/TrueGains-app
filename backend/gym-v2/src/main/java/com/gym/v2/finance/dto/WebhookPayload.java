package com.gym.v2.finance.dto;

/**
 * Ödeme Webhook Bildirimleri için Veri Transfer Nesnesi (WebhookPayload Record)
 */
public record WebhookPayload(String sessionId, String status) {
}
