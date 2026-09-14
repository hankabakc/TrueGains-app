package com.gym.v2.membership.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Şifre değiştirme isteği DTO'su.
 * <p>
 * Yeni şifre kuralları, kayıt (RegisterRequest) ile birebir aynıdır: en az 10 karakter,
 * en az bir büyük harf, bir küçük harf, bir rakam ve bir özel karakter.
 * </p>
 */
public record ChangePasswordRequest(@NotBlank(message = "{validation.auth.password.notBlank}") String currentPassword,

		@NotBlank(message = "{validation.password.notblank}") @Size(min = 10, max = 128,
				message = "{validation.password.size}") @Pattern(
						regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&.\\-_])[A-Za-z\\d@$!%*?&.\\-_]{10,}$",
						message = "{validation.password.pattern}") String newPassword) {
}
