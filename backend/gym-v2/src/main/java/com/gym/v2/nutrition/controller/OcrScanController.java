package com.gym.v2.nutrition.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.service.UserService;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import com.gym.v2.nutrition.dto.OcrScanResponse;
import com.gym.v2.nutrition.service.GeminiVisionService;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.io.InputStream;

@RestController
@RequestMapping("/api/v1/nutrition/ocr")
public class OcrScanController {

	private final GeminiVisionService geminiVisionService;

	private final UserService userService;

	private final Clock clock;

	public OcrScanController(GeminiVisionService geminiVisionService, UserService userService, Clock clock) {
		this.geminiVisionService = geminiVisionService;
		this.userService = userService;
		this.clock = clock;
	}

	/**
	 * Görsel boyut sınırı. Spring'in genel {@code max-file-size} ayarı 20MB'dır ve bu uç
	 * için fazla yüksek: {@code GeminiVisionService} dosyayı belleğe alıp base64'e
	 * çeviriyor ve JSON gövdesine gömüyor, yani tek istek için ham boyutun ~3 katı heap
	 * harcanıyor. Üstelik aynı veri Gemini'ye gönderildiği için token maliyeti de boyutla
	 * artıyor. {@code /api/v1/files/upload} ucundaki 5MB sınırıyla hizalandı.
	 */
	private static final long MAX_IMAGE_BYTES = 5L * 1024 * 1024;

	@PostMapping("/scan")
	public ApiResponse<OcrScanResponse> scanFoodImage(@RequestParam("file") MultipartFile file) {
		if (file.isEmpty()) {
			throw new BadRequestException("Lütfen analiz edilecek bir fotoğraf yükleyin.");
		}

		if (file.getSize() > MAX_IMAGE_BYTES) {
			throw new BadRequestException("Fotoğraf en fazla 5 MB olabilir. Lütfen daha küçük bir görsel seçin.");
		}

		// Güvenlik Kontrolü: MIME Tipi Doğrulaması
		String contentType = file.getContentType();
		if (contentType == null || (!contentType.equals("image/jpeg") && !contentType.equals("image/png")
				&& !contentType.equals("image/webp"))) {
			throw new BadRequestException("Sadece görsel dosyaları (.jpg, .png, .webp) yüklenebilir.");
		}

		// Güvenlik Kontrolü: Magic Bytes (Dosya İmzası) Doğrulaması (B-SEC-2)
		// ImageIO.read yerine sadece ilk 12 byte okunarak OOM/DoS riskleri önlenir.
		try (InputStream is = file.getInputStream()) {
			byte[] header = new byte[12];
			int read = is.read(header);
			if (read < 3) {
				throw new BadRequestException("Geçersiz görsel dosyası (Dosya çok küçük).");
			}

			if (!isValidImageHeader(header, read)) {
				throw new BadRequestException("Yüklenen dosya içeriği geçerli bir görsel değil.");
			}
		}
		catch (IOException e) {
			throw new BadRequestException("Dosya doğrulanırken bir hata oluştu.");
		}

		AppUser currentUser = userService.getCurrentUser();
		OcrScanResponse response = geminiVisionService.analyzeFoodLabel(file, currentUser);

		if (response.limitReached() != null && response.limitReached()) {
			throw new BadRequestException(response.assistantMessage());
		}

		return ApiResponse.success(response, "Yapay zeka analizi başarıyla tamamlandı.", clock.instant());
	}

	private boolean isValidImageHeader(byte[] header, int read) {
		// JPEG: FF D8 FF
		if (read >= 3 && header[0] == (byte) 0xFF && header[1] == (byte) 0xD8 && header[2] == (byte) 0xFF) {
			return true;
		}
		// PNG: 89 50 4E 47 0D 0A 1A 0A
		if (read >= 8 && header[0] == (byte) 0x89 && header[1] == (byte) 0x50 && header[2] == (byte) 0x4E
				&& header[3] == (byte) 0x47 && header[4] == (byte) 0x0D && header[5] == (byte) 0x0A
				&& header[6] == (byte) 0x1A && header[7] == (byte) 0x0A) {
			return true;
		}
		// WEBP: RIFF (bytes 0-3) + WEBP (bytes 8-11)
		if (read >= 12 && header[0] == (byte) 'R' && header[1] == (byte) 'I' && header[2] == (byte) 'F'
				&& header[3] == (byte) 'F') {
			return header[8] == (byte) 'W' && header[9] == (byte) 'E' && header[10] == (byte) 'B'
					&& header[11] == (byte) 'P';
		}
		return false;
	}

}
