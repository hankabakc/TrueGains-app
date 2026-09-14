package com.gym.v2.core.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sentry entegrasyonunu doğrulamak için geçici test controller. Adım 3.1 kapsamında
 * oluşturulmuştur.
 */
@RestController
@RequestMapping("/api/v2/test/sentry")
public class SentryTestController {

	@GetMapping("/error")
	public void triggerError() {
		throw new RuntimeException("Sentry Backend QA Test: Kontrollü 500 Hatası");
	}

}
