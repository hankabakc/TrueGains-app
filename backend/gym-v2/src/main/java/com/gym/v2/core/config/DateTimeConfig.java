package com.gym.v2.core.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;
import java.time.ZoneId;

/**
 * Uygulama genelinde tarih ve zaman yönetimi için merkezi yapılandırma. Statik
 * LocalDate.now() çağrıları yerine Clock bean'i enjekte edilmelidir.
 */
@Configuration
public class DateTimeConfig {

	@Value("${app.timezone:Europe/Istanbul}")
	private String zoneId;

	@Bean
	public Clock clock() {
		// Uygulamanın belirlenen saat dilimine göre çalışmasını sağlar (Today mismatches
		// fix)
		return Clock.system(ZoneId.of(zoneId));
	}

}
