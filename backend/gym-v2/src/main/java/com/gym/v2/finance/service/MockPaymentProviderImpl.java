package com.gym.v2.finance.service;

import com.gym.v2.finance.dto.CheckoutSessionResponse;
import com.gym.v2.finance.entity.Order;
import org.springframework.stereotype.Service;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Sahte Ödeme Sağlayıcı Servis Entegrasyon Sınıfı. Stripe/Iyzico checkout flow
 * simülasyonu yapar.
 * <p>
 * Gerçek sağlayıcıda ödemenin sonucunu <b>sağlayıcı</b> bilir; burada onun yerine
 * bellekte tutulan bir tablo geçer ve sonucu simülasyon ekranı yazar
 * ({@code MockGatewayController}). Gerçek entegrasyon geldiğinde bu sınıf ve o
 * denetleyici birlikte silinir; {@code FinanceService} tarafında değişiklik gerekmez.
 * </p>
 */
@Service
public class MockPaymentProviderImpl implements PaymentGatewayService {

	// ponytail: bellek içi tablo yeterli; mock sağlayıcı yeniden başlatmayı atlatmak
	// zorunda değil. Gerçek sağlayıcıda bu bilgi zaten sağlayıcıda durur.
	private final Map<String, PaymentOutcome> outcomes = new ConcurrentHashMap<>();

	@Override
	public CheckoutSessionResponse createCheckoutSession(Order order) {
		// Mock Session ID ve sahte bir ödeme/checkout url adresi oluşturulur.
		String sessionId = "mock_sess_" + UUID.randomUUID().toString().substring(0, 8);
		// Frontend, checkout işlemine tıkladığında yönleneceği Stripe benzeri simülasyon
		// URL'i
		String paymentUrl = "/checkout/gateway?session_id=" + sessionId;

		outcomes.put(sessionId, PaymentOutcome.PENDING);
		return new CheckoutSessionResponse(sessionId, paymentUrl);
	}

	@Override
	public PaymentOutcome verifyPayment(String checkoutSessionId) {
		return outcomes.getOrDefault(checkoutSessionId, PaymentOutcome.PENDING);
	}

	/**
	 * Simülasyon ekranının ödeme sonucunu bildirdiği giriş noktası. Gerçek bir
	 * sağlayıcıda bu, kullanıcının bankada kart bilgisini onaylamasına karşılık gelir.
	 */
	public void recordSimulatedOutcome(String checkoutSessionId, PaymentOutcome outcome) {
		outcomes.put(checkoutSessionId, outcome);
	}

}
