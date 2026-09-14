package com.gym.v2;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableCaching
@EnableScheduling
public class GymappApplication {

	public static void main(String[] args) {
		// .env dosyasını yükle ve sistem özelliklerine (System Properties) aktar.
		// Bu sayede application.properties içindeki ${VARIABLE} yapıları otomatik dolar.
		Dotenv dotenv = Dotenv.configure().directory("./").ignoreIfMissing().load();

		dotenv.entries().forEach(entry -> System.setProperty(entry.getKey(), entry.getValue()));

		SpringApplication.run(GymappApplication.class, args);
	}

}
