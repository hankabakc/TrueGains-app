package com.gym.v2.training.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Sporcunun bir egzersizdeki gelişim verilerini taşıyan record. Progressive Overload
 * analizi için kullanılır.
 *
 * @param date Logun oluşturulduğu tarih
 * @param oneRepMax Hesaplanan 1RM (One Rep Max) ağırlığı
 * @param maxWeight O oturumda kaldırılan en yüksek ham ağırlık
 * @param totalSets O oturumda yapılan toplam set sayısı
 */
public record ExerciseProgressRecord(Instant date, BigDecimal oneRepMax, BigDecimal maxWeight, Integer totalSets) {
}
