package com.gym.v2.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Telefon doğrulama isteği.
 * <p>
 * Bu uç daha önce hem e-postayı hem <b>OTP kodunu</b> {@code @RequestParam} ile alıyordu:
 * ikisi de URL'in sorgu dizesinde taşınıyor, dolayısıyla ters vekil erişim loglarına,
 * Sentry breadcrumb'larına ve WAF log satırlarına <b>ham hâliyle</b> düşüyordu. Loglara
 * erişebilen biri, kullanıcının doğrulama kodunu okuyabilir.
 * </p>
 */
public record VerifyOtpRequest(
		@NotBlank(message = "{validation.email.notblank}") @Email(message = "{validation.email.invalid}") @Size(
				max = 255, message = "{validation.email.size}") String email,

		@NotBlank(message = "Doğrulama kodu zorunludur.") @Size(min = 4, max = 10,
				message = "Doğrulama kodu geçersiz.") String code) {
}
