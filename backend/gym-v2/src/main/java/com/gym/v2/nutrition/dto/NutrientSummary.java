package com.gym.v2.nutrition.dto;

import java.math.BigDecimal;

/**
 * Besin değerlerini (Makro ve Mikro) tutan immütal record yapısı. BigDecimal[] (Magic
 * Index) kullanımına alternatif olarak tip güvenliği ve okunabilirlik sağlar.
 *
 * @param protein Protein değeri (g)
 * @param carbs Karbonhidrat değeri (g)
 * @param fat Yağ değeri (g)
 * @param calories Enerji değeri (kcal)
 * @param sugar Şeker değeri (g)
 * @param fiber Lif değeri (g)
 * @param sodium Sodyum değeri (mg)
 * @param potassium Potasyum değeri (mg)
 * @param cholesterol Kolesterol değeri (mg)
 */
public record NutrientSummary(BigDecimal protein, BigDecimal carbs, BigDecimal fat, BigDecimal calories,
		BigDecimal sugar, BigDecimal fiber, BigDecimal sodium, BigDecimal potassium, BigDecimal cholesterol) {
	/**
	 * Tüm değerleri sıfır (BigDecimal.ZERO) olan boş bir özet döner.
	 */
	public static NutrientSummary empty() {
		return new NutrientSummary(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO,
				BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
	}
}
