package com.gym.v2.security;

import com.gym.v2.core.security.config.SecurityConfig;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * CORS yapılandırması.
 * <p>
 * Bu ayar sessizce yanlış kalabilen türden: mobil uygulama CORS kullanmadığı için hatalı
 * yapılandırma geliştirme sırasında hiç fark edilmez, yalnızca web sürümü yayınlandığında
 * ortaya çıkar — ve o noktada tarayıcı <b>tüm</b> istekleri bloklar.
 * </p>
 */
class CorsConfigurationTest {

	private UrlBasedCorsConfigurationSource sourceFor(List<String> origins) {
		SecurityConfig config = new SecurityConfig(null, null);
		ReflectionTestUtils.setField(config, "allowedOrigins", origins);
		return (UrlBasedCorsConfigurationSource) config.corsConfigurationSource();
	}

	@Test
	void configuredOrigins_areApplied() {
		UrlBasedCorsConfigurationSource source = sourceFor(List.of("https://gymapp.example"));

		CorsConfiguration cors = source.getCorsConfigurations().get("/**");

		assertThat(cors.getAllowedOrigins()).containsExactly("https://gymapp.example");
		assertThat(cors.getAllowCredentials()).isTrue();
	}

	/**
	 * Joker origin, kimlik bilgisi taşıyan isteklerde tarayıcı tarafından reddedilir.
	 * Spring bunu ancak <b>istek anında</b> fark edip anlaşılmaz bir hata veriyordu;
	 * açılışta ve açık mesajla durmak, hatayı üretimde ilk isteği atan kullanıcının
	 * bulmasından iyi.
	 */
	@Test
	void wildcardOrigin_isRejectedAtStartup() {
		assertThatThrownBy(() -> sourceFor(List.of("*"))).isInstanceOf(IllegalStateException.class)
			.hasMessageContaining("allowed-origins");
	}

	@Test
	void wildcardMixedWithRealOrigin_isAlsoRejected() {
		// Listeye "bir de her ihtimale karşı *" eklemek en sık yapılan hata.
		assertThatThrownBy(() -> sourceFor(List.of("https://gymapp.example", "*")))
			.isInstanceOf(IllegalStateException.class);
	}

}
