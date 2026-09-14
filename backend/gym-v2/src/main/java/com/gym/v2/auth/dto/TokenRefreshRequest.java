package com.gym.v2.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Token yenileme (refresh token) isteği için sadece cihaz bilgisini taşıyan record.
 * <p>
 * Süresi dolmuş bir erişim token'ını yenilemek için istemci tarafından gönderilir. Not:
 * Refresh token güvenlik amacıyla Body yerine HttpOnly Cookie üzerinden alınmaktadır.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> İstemci, sadece {@code deviceId} bilgisini gönderir ve
 * tarayıcı/istemci HttpOnly çerezini otomatik yollar. Sunucu, bu token'ın veritabanında
 * geçerli olup olmadığını ve belirtilen cihaza ait olup olmadığını kontrol eder.
 *
 * @param deviceId İşlemin yapıldığı cihazın benzersiz kimliği.
 */
public record TokenRefreshRequest(@NotBlank(message = "{validation.deviceid.notblank}") @Size(max = 100,
		message = "{validation.deviceid.size}") String deviceId) {
}
