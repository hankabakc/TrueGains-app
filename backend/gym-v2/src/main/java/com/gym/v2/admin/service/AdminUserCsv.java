package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminUserRowDto;
import com.gym.v2.auth.entity.UserRole;
import java.time.Instant;
import java.util.List;

/**
 * Kullanici satirlarini CSV metnine cevirir.
 * <p>
 * Ayirici noktali virgul: Turkce Excel virgulu ondalik ayirici sayar ve virgullu dosyayi
 * tek sutunda acar. Zamanlar ISO-8601 UTC. BOM'u dosyayi olusturan panel ekler.
 * </p>
 * <p>
 * <b>Formul enjeksiyonu:</b> e-posta ve ad kullanicinin yazdigi metindir.
 * {@code = + - @}, sekme veya satir basi ile baslayan hucreyi Excel formul olarak
 * calistirir; basina tek tirnak eklenir.
 * </p>
 */
final class AdminUserCsv {

	static final String HEADER = "E-posta;Ad;Rol;Durum;Premium;Kayıt (UTC);Son giriş (UTC)";

	private static final String FORMULA_PREFIXES = "=+-@\t\r";

	private AdminUserCsv() {
	}

	static String toCsv(List<AdminUserRowDto> rows) {
		StringBuilder csv = new StringBuilder(HEADER).append("\r\n");
		for (AdminUserRowDto row : rows) {
			csv.append(cell(row.email()))
				.append(';')
				.append(cell(row.fullName()))
				.append(';')
				.append(cell(roleLabel(row.role())))
				.append(';')
				.append(row.active() ? "aktif" : "pasif")
				.append(';')
				.append(row.premium() ? "evet" : "hayır")
				.append(';')
				.append(time(row.registeredAt()))
				.append(';')
				.append(time(row.lastLoginAt()))
				.append("\r\n");
		}
		return csv.toString();
	}

	/** Hucreyi tirnaklar; formul olarak calisabilecek metni etkisizlestirir. */
	static String cell(String value) {
		if (value == null) {
			return "";
		}
		String safe = value;
		if (!safe.isEmpty() && FORMULA_PREFIXES.indexOf(safe.charAt(0)) >= 0) {
			safe = "'" + safe;
		}
		return "\"" + safe.replace("\"", "\"\"") + "\"";
	}

	private static String roleLabel(UserRole role) {
		return switch (role) {
			case CLIENT -> "Sporcu";
			case COACH -> "Antrenör";
			case ADMIN -> "Yönetici";
			default -> role.name();
		};
	}

	private static String time(Instant value) {
		return value == null ? "" : value.toString();
	}

}
