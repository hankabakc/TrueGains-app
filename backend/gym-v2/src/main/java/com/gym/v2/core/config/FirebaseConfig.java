package com.gym.v2.core.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Firebase Admin SDK konfigürasyon sınıfı. Uygulama başlatıldığında FirebaseApp'i
 * initialize eder.
 */
@Configuration
public class FirebaseConfig {

	private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

	private final ResourceLoader resourceLoader;

	@Value("${firebase.credential.path}")
	private String credentialPath;

	public FirebaseConfig(ResourceLoader resourceLoader) {
		this.resourceLoader = resourceLoader;
	}

	@PostConstruct
	public void initialize() {
		try {
			if (FirebaseApp.getApps().isEmpty()) {
				Resource resource = resourceLoader.getResource(credentialPath);
				try (InputStream serviceAccount = resource.getInputStream()) {
					FirebaseOptions options = FirebaseOptions.builder()
						.setCredentials(GoogleCredentials.fromStream(serviceAccount))
						.build();

					FirebaseApp.initializeApp(options);
				}
			}
		}
		catch (IOException e) {
			// Uygulamayi DURDURMAZ. Onceden burada RuntimeException firlatiliyordu ve
			// kimlik dosyasi sunucuya kopyalanmadiysa dagitim "bildirimler calismiyor"
			// degil "uygulama hic acilmiyor" seklinde basarisiz oluyordu — saglik ucu da
			// olmadigi icin sebebi loglardan araniyordu.
			// Bildirim gonderimi zaten hatayi yutuyor (bkz. NotificationService), yani
			// Firebase olmadan uygulamanin geri kalani calisir.
			log.error("Firebase Admin SDK baslatilamadi; push bildirimleri devre disi. Sebep: {}", e.getMessage());
		}
	}

}
