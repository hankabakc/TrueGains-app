package com.gym.v2.finance.dto;

/**
 * Satın alma niyeti detaylarını içeren record DTO. Pure Java (Lombok YASAK) kuralına
 * uygun olarak record olarak tanımlanmıştır.
 *
 * @param type Satın alma tipi ("NONE", "DIFFERENT_COACH", "SAME_COACH_DIFFERENT_PACKAGE")
 * @param currentCoachName Mevcut aktif koçun tam adı
 */
public record PurchaseIntentDTO(String type, String currentCoachName) {
}
