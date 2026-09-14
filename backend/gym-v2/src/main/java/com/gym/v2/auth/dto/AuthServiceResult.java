package com.gym.v2.auth.dto;

/**
 * Kimlik doğrulama işlemleri sonucunda üretilen verileri, katmanlar arası taşıma amacıyla
 * kullanılan sızdırmaz nesne.
 *
 * @param response İstemciye (body) dönecek olan yanıt nesnesi.
 * @param refreshToken Cookie olarak set edilecek olan yenileme token'ı.
 */
public record AuthServiceResult(AuthResponse response, String refreshToken) {
}
