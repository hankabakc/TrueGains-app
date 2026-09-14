package com.gym.v2.core.security;

import org.jsoup.Jsoup;
import org.jsoup.safety.Safelist;
import org.springframework.stereotype.Component;

/**
 * Stored XSS saldırılarını engellemek için HTML temizleyici. Kullanıcı girdilerinden
 * tehlikeli HTML etiketlerini ayıklar. Jsoup kütüphanesi ile modern ve güvenli
 * sanitizasyon sağlar.
 */
@Component
public class HtmlSanitizer {

	/**
	 * Girdiyi HTML etiketlerinden arındırır. Safelist.none() kullanarak hiçbir HTML
	 * etiketine izin vermez (Plain Text).
	 */
	public String sanitize(String input) {
		if (input == null || input.isBlank()) {
			return input;
		}

		// Güvenlik Bulgu #1: Regex yerine Jsoup.clean() kullanılıyor.
		// Safelist.none() her türlü etiketi (script, img, a vb.) tamamen temizler.
		return Jsoup.clean(input, Safelist.none()).trim();
	}

}
