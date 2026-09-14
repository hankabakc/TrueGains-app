package com.gym.v2.auth.dto;

import com.gym.v2.auth.entity.UserRole;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Kurumsal standartlarda (OAuth2 uyumlu) kimlik doğrulama yanıtı.
 * <p>
 * Bu nesne, kullanıcı bilgilerini gruplar ve token detaylarını standart isimlendirmelerle
 * sunar.
 * </p>
 *
 * @param user Kullanıcının temel bilgilerini içeren nesne.
 * @param accessToken Erişim token'ı (access_token).
 * @param tokenType Token tipi (token_type - örn. Bearer).
 * @param expiresIn Token geçerlilik süresi (expires_in - saniye).
 * @param refreshToken Yenileme token'ı (Sadece sızmaması için @JsonIgnore ile
 * işaretlenmiştir).
 */
public record AuthResponse(@JsonProperty("user") UserInfo user,

		@JsonProperty("access_token") String accessToken,

		@JsonProperty("token_type") String tokenType,

		@JsonProperty("expires_in") Long expiresIn) {
	/**
	 * Kullanıcı bilgilerini hiyerarşik olarak gruplayan iç record.
	 */
	public record UserInfo(Long id, String externalId, String email, UserRole role) {
	}
}
