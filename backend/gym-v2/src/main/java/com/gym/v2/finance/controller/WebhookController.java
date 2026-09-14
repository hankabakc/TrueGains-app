package com.gym.v2.finance.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.finance.dto.WebhookPayload;
import com.gym.v2.finance.service.FinanceService;
import org.springframework.web.bind.annotation.*;
import java.time.Clock;

/**
 * 3. Parti Ödeme Sağlayıcılarından Gelen Asenkron Bildirimleri (Webhook) Yöneten
 * Controller Sınıfı. Güvenlik kurallarından (JWT) muaf tutulmuştur.
 */
@RestController
@RequestMapping("/api/v1/webhooks")
public class WebhookController {

	private final FinanceService financeService;

	private final Clock clock;

	// Constructor Injection (Pure Java)
	public WebhookController(FinanceService financeService, Clock clock) {
		this.financeService = financeService;
		this.clock = clock;
	}

	/**
	 * Ödeme sağlayıcısından dönen durum bildirimini işler.
	 */
	/**
	 * Gövdedeki {@code status} alanı bilinçli olarak kullanılmaz: bildirimi kimin
	 * gönderdiği doğrulanmadığı sürece ona güvenilemez. Ödemenin sonucu sağlayıcıya
	 * sorulur.
	 */
	@PostMapping("/payment")
	public ApiResponse<Void> handlePaymentNotification(@RequestBody WebhookPayload payload) {
		financeService.handlePaymentWebhook(payload.sessionId());
		return ApiResponse.success(null, "Webhook bildirimi başarıyla işlendi.", clock.instant());
	}

}
//
