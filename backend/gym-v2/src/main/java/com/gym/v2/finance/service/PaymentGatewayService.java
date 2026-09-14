package com.gym.v2.finance.service;

import com.gym.v2.finance.dto.CheckoutSessionResponse;
import com.gym.v2.finance.entity.Order;

/**
 * Ödeme Sağlayıcı Servis Arayüzü
 */
public interface PaymentGatewayService {

	CheckoutSessionResponse createCheckoutSession(Order order);

	/**
	 * Ödemenin gerçekten alınıp alınmadığını <b>sağlayıcıya sorar</b>.
	 * <p>
	 * Webhook isteğinin gövdesindeki duruma güvenilmez: o gövdeyi kimin gönderdiği
	 * doğrulanamaz, dolayısıyla "SUCCESS" yazan bir istek bedava abonelik anlamına
	 * gelirdi. Gerçek entegrasyonda bu metot sağlayıcının API'sini çağırır.
	 * </p>
	 * @param checkoutSessionId sağlayıcının ödeme oturumu kimliği
	 * @return ödemenin sağlayıcı tarafındaki gerçek sonucu
	 */
	PaymentOutcome verifyPayment(String checkoutSessionId);

}
