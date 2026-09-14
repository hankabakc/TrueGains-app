package com.gym.v2.finance.service;

/**
 * Bir ödeme oturumunun sağlayıcı tarafındaki sonucu.
 */
public enum PaymentOutcome {

	/** Ödeme alındı. */
	SUCCESS,

	/** Ödeme başarısız oldu veya iptal edildi. */
	FAILED,

	/** Sağlayıcı henüz sonuçlandırmadı; sipariş bekletilir. */
	PENDING

}
