package com.gym.v2.core.config;

import io.sentry.Sentry;
import io.sentry.SentryOptions;
import io.sentry.protocol.User;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * GYMAPP-V2 Sentry Güvenlik Yapılandırması. "Nükleer Zırh" güvenlik politikası gereği,
 * Sentry'ye gönderilen hata raporlarındaki PII (Kişisel Veriler) bu sınıf üzerinden
 * maskelenir. "Pure Java" politikasına uygundur.
 */
@Configuration
public class SentrySecurityConfig {

	@Value("${sentry.dsn}")
	private String sentryDsn;

	@PostConstruct
	public void initSentry() {
		if (sentryDsn != null && !sentryDsn.isBlank() && !Sentry.isEnabled()) {
			Sentry.init(options -> {
				options.setDsn(sentryDsn);
				options.setTracesSampleRate(1.0);
				options.setBeforeSend(sentryBeforeSendCallback());
			});
		}
	}

	/**
	 * Sentry'ye gönderilen her event öncesi tetiklenen callback. Hassas verileri
	 * temizler.
	 * @return BeforeSendCallback bean'i
	 */
	@Bean
	public SentryOptions.BeforeSendCallback sentryBeforeSendCallback() {
		return (event, hint) -> {
			// 1. Kullanıcı Verilerini Maskele (E-posta ve IP)
			User user = event.getUser();
			if (user != null) {
				if (user.getEmail() != null) {
					user.setEmail("[MASKED]");
				}
				if (user.getIpAddress() != null) {
					user.setIpAddress("[MASKED]");
				}
			}

			// 2. Request ve Breadcrumb verileri SDK tarafından varsayılan olarak güvenli
			// işlenir.

			return event;
		};
	}

}
