package com.gym.v2.core.security;

/**
 * Merkezi Güvenlik Sabitleri (Security Constants). Proje genelinde kullanılan
 * Authorization başlığı, Token ön ekleri ve diğer güvenlik string'lerini barındırır.
 */
public final class SecurityConstants {

	private SecurityConstants() {
		// Utility class
	}

	public static final String AUTH_HEADER = "Authorization";

	public static final String BEARER_PREFIX = "Bearer ";

	public static final String DEFAULT_DEVICE_ID = "REGISTERED_DEVICE";

	// Token Geçerlilik Süreleri
	public static final long REFRESH_TOKEN_EXPIRY_DAYS = 30;

	public static final long BLACKLIST_TOKEN_EXPIRY_HOURS = 24;

	// Cookie Ayarları
	public static final String REFRESH_TOKEN_COOKIE_NAME = "refresh_token";

	// Bulgu #13: Cookie süresi, Refresh Token veritabanı geçerlilik süresiyle (30 gün)
	// senkronize edildi.
	public static final long REFRESH_TOKEN_COOKIE_MAX_AGE = REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60;

}
