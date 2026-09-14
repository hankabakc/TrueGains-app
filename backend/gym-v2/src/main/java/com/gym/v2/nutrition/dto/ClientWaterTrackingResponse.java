package com.gym.v2.nutrition.dto;

/**
 * Koç için öğrencinin su tüketim ve hedef bilgilerini taşıyan DTO. Pure Java (Lombok yok)
 * ve record yapısına uygun olarak tasarlanmıştır.
 *
 * @param clientId Öğrencinin benzersiz kimliği
 * @param firstName Öğrencinin adı
 * @param lastName Öğrencinin soyadı
 * @param profilePhotoUrl Öğrencinin profil fotoğrafı adresi
 * @param targetWaterMl Öğrencinin günlük hedef su tüketim miktarı (ml)
 * @param consumedWaterMl Öğrencinin o güne ait toplam tükettiği su miktarı (ml)
 */
public record ClientWaterTrackingResponse(Long clientId, String firstName, String lastName, String profilePhotoUrl,
		Integer targetWaterMl, Integer consumedWaterMl) {
}
