package com.gym.v2.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Kullanıcı giriş (login) isteği için gerekli verileri taşıyan record.
 * <p>
 * Bu nesne, kullanıcının sisteme giriş yapabilmesi için gereken kimlik bilgilerini ve
 * giriş yaptığı cihazın benzersiz kimliğini içerir.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> İstemci tarafında bu alanlar doldurularak {@code /auth/login}
 * uç noktasına (endpoint) gönderilir. Gelen veriler Jakarta Bean Validation
 * kısıtlamalarına göre otomatik olarak doğrulanır.
 *
 * <h2>Neden Bu Nesne Var?</h2> Giriş işlemi sırasında gereken verileri kapsüllemek
 * (encapsulate) ve API katmanında tip güvenliği sağlamak için kullanılır.
 *
 * @param email Kullanıcının kayıtlı e-posta adresi.
 * @param password Kullanıcının giriş şifresi.
 * @param deviceId Giriş yapılan cihazın benzersiz kimliği (Refresh Token yönetimi için
 * gereklidir).
 */
public record LoginRequest(
		@NotBlank(message = "{validation.email.notblank}") @Email(message = "{validation.email.invalid}") @Pattern(
				regexp = "^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$",
				message = "{validation.email.pattern}") @Size(max = 255,
						message = "{validation.email.size}") String email,

		@NotBlank(message = "{validation.password.notblank}") @Size(min = 8, max = 128,
				message = "{validation.password.size}") String password,

		@NotBlank(message = "{validation.deviceid.notblank}") @Size(max = 100,
				message = "{validation.deviceid.size}") String deviceId) {
}
