package com.gym.v2.core.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Telefon numarası henüz doğrulanmamış bir hesapla oturum açılmaya çalışıldığında
 * fırlatılır.
 * <p>
 * 403 (Forbidden) ile döner; istemci bu durumu OTP doğrulama ekranına yönlendirmek için
 * kullanır. Güvenlik politikası: telefon doğrulanana kadar erişim token'ı verilmez.
 * </p>
 */
@ResponseStatus(HttpStatus.FORBIDDEN)
public class PhoneNotVerifiedException extends RuntimeException {

	public PhoneNotVerifiedException(String message) {
		super(message);
	}

}
