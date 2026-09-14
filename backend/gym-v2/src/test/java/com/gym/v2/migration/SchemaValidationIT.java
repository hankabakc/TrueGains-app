package com.gym.v2.migration;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Şema kayması (drift) testi.
 * <p>
 * {@link FlywayMigrationIT} migration'ların çalıştığını doğrular; bu test ise ortaya
 * çıkan şemanın entity'lerle uyuştuğunu doğrular. Diğer testler şemayı Hibernate'e
 * ürettirdiği için entity'de olup migration'da olmayan bir sütun fark edilmez ve ancak
 * deploy'da patlar.
 * </p>
 * <p>
 * Doğrulamayı Hibernate'in kendisi yapar: Flyway migration'ları uygular, ardından
 * {@code ddl-auto=validate} şemayı entity'lerle karşılaştırır. Uyuşmazlık varsa uygulama
 * context'i hiç ayağa kalkmaz ve test kırmızıya döner.
 * </p>
 */
@SpringBootTest
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class SchemaValidationIT {

	@Container
	private static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:17-alpine");

	@DynamicPropertySource
	static void useRealPostgres(DynamicPropertyRegistry registry) {
		registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
		registry.add("spring.datasource.username", POSTGRES::getUsername);
		registry.add("spring.datasource.password", POSTGRES::getPassword);
		registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
		registry.add("spring.jpa.database-platform", () -> "org.hibernate.dialect.PostgreSQLDialect");
		registry.add("spring.flyway.enabled", () -> "true");
		registry.add("spring.jpa.hibernate.ddl-auto", () -> "validate");
	}

	@Test
	void entitiesMatchTheMigratedSchema() {
		// Context ayağa kalktıysa Hibernate doğrulaması geçmiştir; ayrıca assertion
		// gerekmez.
	}

}
