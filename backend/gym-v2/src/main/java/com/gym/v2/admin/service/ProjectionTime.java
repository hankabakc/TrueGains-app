package com.gym.v2.admin.service;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

/**
 * Yerel (native) sorgudan donen zaman degerini {@link Instant}'a cevirir.
 * <p>
 * <b>Neden gerekli:</b> {@code TIMESTAMPTZ} sutunu surucuye gore FARKLI Java tipiyle
 * geliyor - gercek PostgreSQL {@link Instant}, testlerdeki H2 ise {@link OffsetDateTime}.
 * Projeksiyon arayuzune bunlardan birini yazmak, digerinde "Cannot project X to Y" ile
 * 500'e yol aciyor.
 * </p>
 * <p>
 * Bu tuzaga bir kez dusuldu: projeksiyon {@code Instant} iken H2 testi kirmizi verdi,
 * {@code OffsetDateTime} yapilinca testler yesillendi ama URETIM (PostgreSQL) kirildi.
 * Tipi projeksiyonda sabitlemek yerine burada normallestiriyoruz.
 * </p>
 */
final class ProjectionTime {

	private ProjectionTime() {
	}

	/**
	 * @param value surucunun dondurdugu ham deger
	 * @return UTC anı, deger yoksa {@code null}
	 * @throws IllegalStateException taninmayan bir zaman tipi gelirse - sessizce
	 * {@code null} donmek, ekranda "—" gosterip sorunu gizlerdi
	 */
	static Instant toInstant(Object value) {
		return switch (value) {
			case null -> null;
			case Instant instant -> instant;
			case OffsetDateTime offsetDateTime -> offsetDateTime.toInstant();
			case Timestamp timestamp -> timestamp.toInstant();
			case LocalDateTime localDateTime -> localDateTime.toInstant(ZoneOffset.UTC);
			default -> throw new IllegalStateException(
					"Beklenmeyen zaman tipi: " + value.getClass().getName() + " (" + value + ")");
		};
	}

}
