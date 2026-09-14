package com.gym.v2.nutrition.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.nutrition.dto.OcrScanResponse;
import java.io.IOException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.multipart.MultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code GeminiVisionService} kota kapısı.
 * <p>
 * Bu kota, Gemini faturasıyla kötüye kullanım arasındaki <b>tek</b> engel: uca özel hız
 * sınırı yok, genel kova dakikada 100 istek. Kapı açık kalırsa maliyet doğrudan faturaya
 * yansır ve bunu gösteren hiçbir alarm yok.
 * </p>
 * <p>
 * Testler ağ çağrısı yapmaz. Kota kapısı HTTP çağrısından <b>önce</b> çalıştığı için
 * reddedilen senaryolar zaten ağa çıkmaz; kapıyı geçen senaryolarda ise dosya okuması
 * hata verecek şekilde ayarlanır, böylece çağrı Gemini'ye ulaşmadan sonlanır.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class GeminiQuotaTest {

	private static final LocalDate TODAY = LocalDate.of(2026, 8, 15);

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private MealLogService mealLogService;

	@Mock
	private MultipartFile file;

	private GeminiVisionService service;

	@BeforeEach
	void setUp() {
		Clock clock = Clock.fixed(TODAY.atStartOfDay(ZoneOffset.UTC).toInstant(), ZoneOffset.UTC);
		service = new GeminiVisionService(userRepository, new ObjectMapper(), mealLogService, clock);
	}

	private AppUser user(boolean premium, int scanCount, LocalDate lastScanDate) {
		AppUser user = AppUser.builder().email("kota@test.com").role(UserRole.CLIENT).build();
		user.setIsPremium(premium);
		user.setDailyScanCount(scanCount);
		user.setLastScanDate(lastScanDate);
		return user;
	}

	/** Kapıyı geçen istekleri ağa çıkmadan sonlandırır. */
	private void makeFileUnreadable() throws IOException {
		when(file.getBytes()).thenThrow(new IOException("test"));
	}

	@Test
	void freeUserAtDailyLimit_isRefusedWithoutCallingTheAi() throws IOException {
		AppUser user = user(false, 4, TODAY);

		OcrScanResponse response = service.analyzeFoodLabel(file, user);

		assertThat(response.limitReached()).isTrue();
		// Reddedilen istek dosyayı hiç okumamalı: okuduysa Gemini'ye giden yolun
		// başlangıcındadır.
		verify(file, never()).getBytes();
		assertThat(user.getDailyScanCount()).isEqualTo(4);
	}

	@Test
	void premiumUserAtDailyCeiling_isRefusedWithoutCallingTheAi() throws IOException {
		AppUser user = user(true, 50, TODAY);

		assertThatThrownBy(() -> service.analyzeFoodLabel(file, user)).isInstanceOf(BadRequestException.class)
			.hasMessageContaining("50");

		verify(file, never()).getBytes();
	}

	@Test
	void premiumUserBelowCeiling_passesTheGateEvenAboveTheFreeLimit() throws IOException {
		// Ücretsiz sınır 4; premium kullanıcı 10 taramayla bu sınırın üstünde ama kendi
		// tavanının (50) altında. Premium atlaması bozulursa burada ücretsiz limit
		// yanıtı döner.
		AppUser user = user(true, 10, TODAY);
		makeFileUnreadable();

		assertThatThrownBy(() -> service.analyzeFoodLabel(file, user)).isInstanceOf(BadRequestException.class);

		verify(file).getBytes();
	}

	@Test
	void counterDoesNotGrowWhenTheCallFails() throws IOException {
		AppUser user = user(false, 1, TODAY);
		makeFileUnreadable();

		assertThatThrownBy(() -> service.analyzeFoodLabel(file, user)).isInstanceOf(BadRequestException.class);

		// Sayaç yalnızca Gemini 200 döndüğünde artar; başarısız çağrı kullanıcının
		// hakkını yakmamalı.
		assertThat(user.getDailyScanCount()).isEqualTo(1);
	}

	@Test
	void newDay_resetsYesterdaysCount() throws IOException {
		// Dün limitini doldurmuş kullanıcı bugün yeniden tarayabilmeli.
		AppUser user = user(false, 4, TODAY.minusDays(1));
		makeFileUnreadable();

		assertThatThrownBy(() -> service.analyzeFoodLabel(file, user)).isInstanceOf(BadRequestException.class);

		assertThat(user.getDailyScanCount()).isZero();
		assertThat(user.getLastScanDate()).isEqualTo(TODAY);
		verify(userRepository).save(any(AppUser.class));
	}

	@Test
	void sameDay_doesNotResetTheCount() {
		// Sıfırlama tarihe bağlı olmalı; her çağrıda sıfırlansa kota hiç dolmaz.
		AppUser user = user(false, 4, TODAY);

		OcrScanResponse response = service.analyzeFoodLabel(file, user);

		assertThat(response.limitReached()).isTrue();
		assertThat(user.getDailyScanCount()).isEqualTo(4);
	}

}
