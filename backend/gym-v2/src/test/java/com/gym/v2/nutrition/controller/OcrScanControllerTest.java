package com.gym.v2.nutrition.controller;

import com.gym.v2.auth.service.UserService;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.nutrition.service.GeminiVisionService;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

/**
 * OCR ucunun boyut sınırı.
 * <p>
 * Sınır olmadığında Spring'in genel 20MB tavanı geçerliydi ve {@code GeminiVisionService}
 * dosyayı belleğe alıp base64'e çevirip JSON'a gömdüğü için tek istek ham boyutun ~3 katı
 * heap harcıyordu. Aynı veri Gemini'ye de gittiğinden token maliyeti de boyutla
 * büyüyordu.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class OcrScanControllerTest {

	@Mock
	private GeminiVisionService geminiVisionService;

	@Mock
	private UserService userService;

	private final Clock clock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);

	private OcrScanController controller() {
		return new OcrScanController(geminiVisionService, userService, clock);
	}

	/** Geçerli JPEG imzasıyla başlayan, istenen boyutta bir dosya üretir. */
	private MockMultipartFile jpegOfSize(int bytes) {
		byte[] content = new byte[bytes];
		content[0] = (byte) 0xFF;
		content[1] = (byte) 0xD8;
		content[2] = (byte) 0xFF;
		return new MockMultipartFile("file", "buyuk.jpg", "image/jpeg", content);
	}

	@Test
	void oversizedImage_isRejectedBeforeReachingTheAiService() {
		MockMultipartFile tooBig = jpegOfSize(6 * 1024 * 1024);

		assertThatThrownBy(() -> controller().scanFoodImage(tooBig)).isInstanceOf(BadRequestException.class)
			.hasMessageContaining("5 MB");

		verify(geminiVisionService, never()).analyzeFoodLabel(any(), any());
		verify(userService, never()).getCurrentUser();
	}

	@Test
	void emptyFile_isRejected() {
		MockMultipartFile empty = new MockMultipartFile("file", "bos.jpg", "image/jpeg", new byte[0]);

		assertThatThrownBy(() -> controller().scanFoodImage(empty)).isInstanceOf(BadRequestException.class);

		verify(geminiVisionService, never()).analyzeFoodLabel(any(), any());
	}

	@Test
	void nonImageContentType_isRejected() {
		MockMultipartFile pdf = new MockMultipartFile("file", "belge.pdf", "application/pdf", new byte[] { 1, 2, 3 });

		assertThatThrownBy(() -> controller().scanFoodImage(pdf)).isInstanceOf(BadRequestException.class);

		verify(geminiVisionService, never()).analyzeFoodLabel(any(), any());
	}

	@Test
	void imageWithWrongMagicBytes_isRejected() {
		MockMultipartFile fake = new MockMultipartFile("file", "sahte.jpg", "image/jpeg",
				new byte[] { 'N', 'O', 'T', 'A', 'N', 'I', 'M', 'G' });

		assertThatThrownBy(() -> controller().scanFoodImage(fake)).isInstanceOf(BadRequestException.class);

		verify(geminiVisionService, never()).analyzeFoodLabel(any(), any());
	}

}
