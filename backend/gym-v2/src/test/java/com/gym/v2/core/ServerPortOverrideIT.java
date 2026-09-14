package com.gym.v2.core;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.Environment;
import org.springframework.test.context.ActiveProfiles;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK, properties = "SERVER_PORT=8099")
@ActiveProfiles("test")
class ServerPortOverrideIT {

	@Autowired
	private Environment environment;

	/**
	 * Vekil host'un 8082'sini tuttuğu için backend'i ayrı bir portta koşabilmek
	 * gerekiyor. Sabit yazılmış port bunu imkânsız kılıyordu.
	 */
	@Test
	void serverPort_isOverridableByEnvironment() {
		assertThat(environment.getProperty("server.port")).isEqualTo("8099");
	}

	/**
	 * Ezme yokken varsayılan 8082 kalmalı: compose'daki expose ve nginx upstream
	 * backend:8082 bu değere bağlı.
	 */
	@Test
	void serverPort_defaultStaysAt8082() throws Exception {
		final Properties raw = new Properties();
		try (InputStream in = getClass().getResourceAsStream("/application.properties")) {
			raw.load(new InputStreamReader(in, StandardCharsets.UTF_8));
		}
		assertThat(raw.getProperty("server.port")).isEqualTo("${SERVER_PORT:8082}");
	}

}
