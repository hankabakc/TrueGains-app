package com.gym.v2.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Yalnızca e-posta taşıyan istekler için gövde nesnesi.
 * <p>
 * Bu uçlar e-postayı daha önce {@code @RequestParam} ile alıyordu, yani adres URL'in
 * sorgu dizesinde taşınıyordu: ters vekil erişim logları, Sentry breadcrumb'ları ve WAF
 * log satırları adresi <b>ham hâliyle</b> kaydediyordu. Kimlik doğrulama servisi
 * gövdedeki e-postaları {@code maskEmail} ile maskeliyor; URL'e konduğunda maskeleme
 * devreye girmiyordu.
 * </p>
 */
public record EmailRequest(@NotBlank(message = "{validation.email.notblank}") @Email(
		message = "{validation.email.invalid}") @Size(max = 255, message = "{validation.email.size}") String email) {
}
