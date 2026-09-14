package com.gym.v2.migration;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.output.MigrateResult;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Migration duman testi (smoke test).
 * <p>
 * Diğer testler şemayı Hibernate'e ({@code ddl-auto=create-drop}) ürettirir; yani
 * {@code db/migration} altındaki SQL dosyaları test sırasında hiç koşmaz. Bozuk bir
 * migration ancak deploy anında ortaya çıkar. Bu test, tüm migration zincirini üretimle
 * aynı sürüm PostgreSQL üzerinde baştan sona uygular.
 * </p>
 * <p>
 * Docker yoksa test çalıştırılmaz (atlanır), build kırılmaz.
 * </p>
 */
@Testcontainers(disabledWithoutDocker = true)
class FlywayMigrationIT {

	// docker-compose.yml ile aynı sürüm; üretimden farklı bir motorda test etmek
	// migration hatalarını gizler.
	@Container
	private static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:17-alpine");

	@Test
	void allMigrationsApplyOnRealPostgres() {
		Flyway flyway = Flyway.configure()
			.dataSource(POSTGRES.getJdbcUrl(), POSTGRES.getUsername(), POSTGRES.getPassword())
			.locations("classpath:db/migration")
			.load();

		MigrateResult result = flyway.migrate();

		assertThat(result.success).isTrue();
		assertThat(result.migrationsExecuted).isPositive();
		// Sırayı bozan veya atlanan bir dosya kalmamalı.
		assertThat(flyway.info().pending()).isEmpty();
	}

}
