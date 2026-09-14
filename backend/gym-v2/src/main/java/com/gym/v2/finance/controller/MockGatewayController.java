package com.gym.v2.finance.controller;

import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.finance.service.FinanceService;
import com.gym.v2.finance.service.MockPaymentProviderImpl;
import com.gym.v2.finance.service.PaymentOutcome;
import java.time.Clock;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Ödeme sağlayıcısının (bankanın) yerine geçen simülasyon denetleyicisi.
 * <p>
 * Uygulamadaki sahte ödeme ekranı burayı çağırır; burası sonucu mock sağlayıcıya yazar ve
 * tıpkı gerçek bir sağlayıcı gibi webhook işleyicisini tetikler. Böylece
 * {@code FinanceService} hiçbir zaman istemcinin bildirdiği duruma güvenmez.
 * </p>
 * <p>
 * Doğrudan {@link MockPaymentProviderImpl} sınıfına bağlıdır: gerçek bir sağlayıcı
 * entegrasyonu gelip mock sınıf silindiğinde bu denetleyici <b>derlenmez</b>, dolayısıyla
 * üretime sızması mümkün değildir.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/mock-gateway")
public class MockGatewayController {

	private final MockPaymentProviderImpl mockProvider;

	private final FinanceService financeService;

	private final Clock clock;

	public MockGatewayController(MockPaymentProviderImpl mockProvider, FinanceService financeService, Clock clock) {
		this.mockProvider = mockProvider;
		this.financeService = financeService;
		this.clock = clock;
	}

	@PostMapping("/pay/{sessionId}/{outcome}")
	public ApiResponse<Void> simulatePayment(@PathVariable String sessionId, @PathVariable String outcome) {
		PaymentOutcome result;
		try {
			result = PaymentOutcome.valueOf(outcome.toUpperCase());
		}
		catch (IllegalArgumentException ex) {
			throw new BadRequestException("Geçersiz ödeme sonucu: " + outcome);
		}

		mockProvider.recordSimulatedOutcome(sessionId, result);
		financeService.handlePaymentWebhook(sessionId);

		return ApiResponse.success(null, "Ödeme simülasyonu tamamlandı.", clock.instant());
	}

}
