package com.gym.v2.core.response;

import java.time.Instant;

/**
 * Tüm API cevapları için standart zarf (wrapper) yapısı. Güvenlik ve mimari standartlar
 * gereği zaman damgası içerir.
 */
public record ApiResponse<T>(boolean success, String message, T data, Instant timestamp) {
	/**
	 * Başarılı işlem cevabı üretir. Bulgu #6: Clock bean uyumu için timestamp dışarıdan
	 * alınmalıdır.
	 */
	public static <T> ApiResponse<T> success(T data, String message, Instant timestamp) {
		return new ApiResponse<>(true, message, data, timestamp);
	}

	/**
	 * Hata cevabı üretir.
	 */
	public static <T> ApiResponse<T> error(String message, Instant timestamp) {
		return new ApiResponse<>(false, message, null, timestamp);
	}

	/**
	 * Veri içeren hata cevabı üretir.
	 */
	public static <T> ApiResponse<T> error(String message, T data, Instant timestamp) {
		return new ApiResponse<>(false, message, data, timestamp);
	}

}
