package com.gym.v2.core.util;

/**
 * Kullanıcıdan gelen dosya adreslerinin tek doğrulama ve saklama biçimi.
 * <p>
 * Adres <b>sunucu adıyla</b> saklanırsa, o adresi açan kullanıcının cihazı oraya istek
 * atar; adres saldırganın sunucusunu gösteriyorsa <b>IP adresi ve içeriğin açılma anı</b>
 * ona gider (takip pikseli). Doğrulama kalıbı bunu tek başına engelleyemez: kalıp
 * dağıtımın sunucu adını bilmez, bu yüzden yalnızca <b>yolu</b> kısıtlar. Asıl koruma
 * {@link #toStoredPath(String)} ile yazma anında yapılır.
 * </p>
 * <p>
 * Aynı mantığın her serviste yeniden yazılmaması için tek yerde tutuluyor: bu projede
 * "aynı kontrolün ikinci kopyası filtresiz kaldı" hatası daha önce yaşandı.
 * </p>
 */
public final class FileUrls {

	/** Adreslerin veritabanında tutulduğu tek biçim. */
	public static final String PATH_PREFIX = "/api/v1/files/";

	/**
	 * Kabul edilen adres kalıbı: kendi dosya ucumuzun yolu, isteğe bağlı sunucu adıyla.
	 * <p>
	 * Sunucu adı hâlâ kabul ediliyor çünkü mağazadan güncelleme almamış kurulumlar
	 * yükleme ucunun döndürdüğü mutlak adresi gönderiyor; reddetmek onlarda gönderimi
	 * kırardı. Saklanmadan önce zaten atılıyor.
	 * </p>
	 */
	public static final String PATTERN = "^$|^(https?://[A-Za-z0-9.:-]+)?/api/v1/files/[A-Za-z0-9._-]+$";

	private FileUrls() {
	}

	/**
	 * Adresten sunucu adını atar; geriye yalnızca yol kalır. Adres beklenen dosya ucunu
	 * göstermiyorsa {@code null} döner — saklanmaz.
	 */
	public static String toStoredPath(String url) {
		if (url == null || url.isBlank()) {
			return null;
		}
		int pathStart = url.indexOf(PATH_PREFIX);
		return pathStart < 0 ? null : url.substring(pathStart);
	}

}
