package com.gym.v2.finance.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.finance.dto.ClientSubscriptionDTO;
import com.gym.v2.finance.dto.PaymentRequestDTO;
import com.gym.v2.finance.service.FinanceService;
import com.gym.v2.finance.service.MockPaymentProviderImpl;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sağlayıcı seçilene kadar kullanılan doğrudan ödeme ucu.
 * <p>
 * <b>Bu uç hiçbir ödeme doğrulaması yapmaz.</b> Kart numarasının 16 haneli olup
 * olmadığına bakar ve aboneliği açar; ne mock ne gerçek bir sağlayıcıya sorar. Test
 * aşamasında satın alma akışının çalışabilmesi için vardır.
 * </p>
 * <p>
 * Daha önce {@code FinanceController} içindeydi ve oradaki tehlike şuydu: gerçek
 * sağlayıcı entegrasyonu gelip {@link MockPaymentProviderImpl} silindiğinde bu uç
 * <b>derlenmeye ve çalışmaya devam edecekti</b> — yani "16 haneli sayı yaz, bedava
 * abonelik al" açığı sessizce üretime geçecekti.
 * </p>
 * <p>
 * Bu yüzden denetleyici {@link MockPaymentProviderImpl}'e <b>bilerek</b> bağımlı
 * kılınmıştır (alan kullanılmasa da constructor'da istenir). Mock sınıf silindiğinde bu
 * dosya derlenmez ve derleyici seni buraya getirir. {@code MockGatewayController} ile
 * aynı koruma deseni.
 * </p>
 * <p>
 * <b>Sağlayıcı bağlanınca yapılacak:</b> bu dosyanın tamamı silinir. Gerçek akış
 * {@code CheckoutController} → {@code /api/v1/checkout/{transactionId}} →
 * {@code FinanceService.initiateCheckout} üzerinden yürür ve sonuç sağlayıcıdan sorulur.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/finance")
public class MockCheckoutController {

	private final FinanceService financeService;

	private final Clock clock;

	/**
	 * @param mockProvider yalnızca derleme bağımlılığı kurmak için istenir; mock sınıf
	 * silindiğinde bu denetleyici de derlenmez ve doğrulamasız ödeme ucu üretime sızamaz
	 */
	public MockCheckoutController(FinanceService financeService, MockPaymentProviderImpl mockProvider, Clock clock) {
		this.financeService = financeService;
		this.clock = clock;
	}

	@PostMapping("/checkout/{transactionId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<ClientSubscriptionDTO> processPaymentForTransaction(@PathVariable Long transactionId,
			@RequestBody PaymentRequestDTO request) {
		AppUser currentClient = financeService.getCurrentUser();
		ClientSubscriptionDTO result = financeService.processPaymentForTransaction(currentClient.getId(), transactionId,
				request);
		return ApiResponse.success(result, "Ödeme başarıyla tamamlandı. Aboneliğiniz aktif edildi!", clock.instant());
	}

}
