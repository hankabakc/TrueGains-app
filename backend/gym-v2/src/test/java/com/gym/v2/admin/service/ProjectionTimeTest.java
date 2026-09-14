package com.gym.v2.admin.service;

import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Sürücüden gelen zaman değerinin normalleştirilmesi.
 * <p>
 * Bu sınıf bir üretim hatasından doğdu: {@code TIMESTAMPTZ} sütunu gerçek PostgreSQL'de
 * {@link Instant}, testlerdeki H2'de {@link OffsetDateTime} olarak geliyor. Projeksiyon
 * arayüzüne tiplerden biri yazılınca öbür sürücüde "Cannot project X to Y" ile 500
 * dönüyordu — ve testler H2'de koştuğu için yeşil kalıyordu.
 * </p>
 */
class ProjectionTimeTest {

	private static final Instant AN = Instant.parse("2026-09-04T09:00:00Z");

	@Test
	void instant_passesThroughUnchanged() {
		assertThat(ProjectionTime.toInstant(AN)).isEqualTo(AN);
	}

	/** Gerçek PostgreSQL'in verdiği tip. */
	@Test
	void offsetDateTime_isConvertedToTheSameMoment() {
		assertThat(ProjectionTime.toInstant(OffsetDateTime.ofInstant(AN, ZoneOffset.UTC))).isEqualTo(AN);
	}

	/** Ofset UTC olmasa da aynı anı vermeli; yerel saate kayma olmamalı. */
	@Test
	void offsetDateTime_withNonUtcOffset_keepsTheSameMoment() {
		assertThat(ProjectionTime.toInstant(OffsetDateTime.ofInstant(AN, ZoneOffset.ofHours(3)))).isEqualTo(AN);
	}

	@Test
	void sqlTimestamp_isConverted() {
		assertThat(ProjectionTime.toInstant(Timestamp.from(AN))).isEqualTo(AN);
	}

	@Test
	void localDateTime_isReadAsUtc() {
		assertThat(ProjectionTime.toInstant(LocalDateTime.ofInstant(AN, ZoneOffset.UTC))).isEqualTo(AN);
	}

	@Test
	void nullValue_staysNull() {
		assertThat(ProjectionTime.toInstant(null)).isNull();
	}

	/**
	 * Tanınmayan tip SESSİZCE {@code null} dönmemeli: ekranda "—" görünür ve sorun
	 * yıllarca fark edilmez. Gürültülü başarısızlık tercih edildi.
	 */
	@Test
	void unknownType_failsLoudlyInsteadOfReturningNull() {
		assertThatThrownBy(() -> ProjectionTime.toInstant("2026-09-04")).isInstanceOf(IllegalStateException.class)
			.hasMessageContaining("Beklenmeyen zaman tipi");
	}

}
