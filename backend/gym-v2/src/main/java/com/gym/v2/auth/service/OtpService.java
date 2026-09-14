package com.gym.v2.auth.service;

import java.security.SecureRandom;
import org.springframework.stereotype.Service;

/**
 * OTP (One-Time Password) üretimi ve SMS gönderim simülasyonunu yöneten servis.
 */
@Service
public class OtpService {

	private final SecureRandom random = new SecureRandom();

	/**
	 * 6 haneli rastgele bir OTP kodu üretir.
	 * @return String Üretilen OTP kodu.
	 */
	public String generateOtp() {
		return String.format("%06d", random.nextInt(1000000));
	}

	/**
	 * Üretilen OTP kodunu simüle edilmiş SMS olarak gönderir. Gerçek bir SMS API'si
	 * bağlanana kadar konsola log basar.
	 * @param phoneNumber Alıcının telefon numarası.
	 * @param otp Üretilen OTP kodu.
	 */
	public void sendOtpSimulation(String phoneNumber, String otp) {
		System.out.println("==================================================");
		System.out.println("📱 [SMS SIMULATION] GÖNDERİLEN NUMARA: " + phoneNumber);
		System.out.println("📩 DOĞRULAMA KODUNUZ: " + otp);
		System.out.println("==================================================");
	}

}
