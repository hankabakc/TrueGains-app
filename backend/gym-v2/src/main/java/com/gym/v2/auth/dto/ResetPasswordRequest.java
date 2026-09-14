package com.gym.v2.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Şifre sıfırlama isteği için kullanılan DTO (Data Transfer Object).
 * <p>
 * Bu DTO, e-posta adresi, doğrulama kodu ve yeni şifre bilgilerini barındırır. E-posta ve
 * şifre formatları kayıt (RegisterRequest) kurallarıyla tam uyumludur.
 * </p>
 *
 * @param email Şifresi sıfırlanacak kullanıcının e-posta adresi.
 * @param code E-posta adresine gönderilen OTP doğrulama kodu.
 * @param newPassword Kullanıcının belirlemek istediği en az 10 karakterlik yeni şifre.
 */
public record ResetPasswordRequest(
		@NotBlank(message = "{validation.email.notblank}") @Email(message = "{validation.email.invalid}") @Pattern(
				regexp = "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$",
				message = "{validation.email.pattern}") @Size(max = 255,
						message = "{validation.email.size}") String email,

		@NotBlank(message = "Doğrulama kodu boş bırakılamaz.") String code,

		@NotBlank(message = "{validation.password.notblank}") @Size(min = 10, max = 128,
				message = "{validation.password.size}") @Pattern(
						regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&.\\-_])[A-Za-z\\d@$!%*?&.\\-_]{10,}$",
						message = "{validation.password.pattern}") String newPassword) {
}
