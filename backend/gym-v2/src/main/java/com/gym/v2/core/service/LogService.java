package com.gym.v2.core.service;

/**
 * GYMAPP-V2 Merkezi Loglama Servis Arayüzü.
 */
public interface LogService {

	/**
	 * Bir istisnayı harici izleme servisine (Örn: Sentry) raporlar.
	 * @param ex Hata nesnesi
	 */
	void error(Throwable ex);

	/**
	 * Bilgilendirme mesajı kaydeder.
	 * @param message Mesaj
	 */
	void info(String message);

}
