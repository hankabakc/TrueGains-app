package com.gym.v2.admin.dto;

/**
 * Sentry'den gelen tek bir hata/cokme kaydi.
 *
 * @param id Sentry sorun kimligi
 * @param title hata basligi
 * @param culprit hatanin gectigi yer
 * @param level seviye (error, warning...)
 * @param count kac kez tekrarladi
 * @param userCount kac kullaniciyi etkiledi
 * @param lastSeen son gorulme (ISO-8601 metin, Sentry ne veriyorsa)
 * @param permalink Sentry'deki adresi
 * @param source hangi proje: BACKEND ya da MOBILE
 */
public record AdminIssueDto(String id, String title, String culprit, String level, long count, long userCount,
		String lastSeen, String permalink, String source) {
}
