package com.gym.v2.finance.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.finance.dto.CheckoutSessionResponse;
import com.gym.v2.finance.service.FinanceService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.Clock;

/**
 * Ödeme Başlatma ve Checkout İşlemlerini Yöneten API Controller.
 */
@RestController
@RequestMapping("/api/v1/finance/checkout")
public class CheckoutController {

	private final FinanceService financeService;

	private final Clock clock;

	// Constructor Injection (Pure Java)
	public CheckoutController(FinanceService financeService, Clock clock) {
		this.financeService = financeService;
		this.clock = clock;
	}

	/**
	 * Sepetteki (bekleyen) bir işlem için 3. parti ödeme oturumu başlatır.
	 */
	@PostMapping("/initiate/{transactionId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<CheckoutSessionResponse> initiateCheckout(@PathVariable Long transactionId) {
		AppUser currentClient = financeService.getCurrentUser();
		CheckoutSessionResponse response = financeService.initiateCheckout(currentClient.getId(), transactionId);
		return ApiResponse.success(response, "Ödeme oturumu başarıyla oluşturuldu.", clock.instant());
	}

}
//
