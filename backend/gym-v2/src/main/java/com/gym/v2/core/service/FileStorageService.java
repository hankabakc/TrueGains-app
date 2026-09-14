package com.gym.v2.core.service;

import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;

import java.io.IOException;
import java.net.MalformedURLException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Dosya depolama işlemlerini yöneten servis. Güvenlik iyileştirmeleri (Boyut kontrolü,
 * dinamik dizin ve doğru hata yönetimi) içerir.
 */
@Service
public class FileStorageService {

	private static final Logger log = LoggerFactory.getLogger(FileStorageService.class);

	private final Path fileStorageLocation;

	private final long maxSizeBytes;

	private static final java.util.List<String> ALLOWED_EXTENSIONS = java.util.Arrays.asList(".jpg", ".jpeg", ".png",
			".pdf");

	/**
	 * Uzantı başına dosyanın ilk baytları (magic number). Yükleme ucu kayıt akışı gereği
	 * kimlik doğrulaması istemediğinden, uzantı adına bakmak yetmez: {@code .jpg} adı
	 * verilen herhangi bir içerik sunucuda barındırılabilir hâle gelirdi.
	 */
	private static final java.util.Map<String, byte[]> MAGIC_NUMBERS = java.util.Map.of(".jpg", bytes(0xFF, 0xD8, 0xFF),
			".jpeg", bytes(0xFF, 0xD8, 0xFF), ".png", bytes(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A), ".pdf",
			bytes(0x25, 0x50, 0x44, 0x46));

	private static byte[] bytes(int... values) {
		byte[] result = new byte[values.length];
		for (int i = 0; i < values.length; i++) {
			result[i] = (byte) values[i];
		}
		return result;
	}

	public FileStorageService(@Value("${app.file.upload-dir:uploads}") String uploadDir,
			@Value("${app.file.max-size-bytes:5242880}") long maxSizeBytes) {

		// Bulgu #4: Upload dizini konfigüre edilebilir hale getirildi.
		this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
		this.maxSizeBytes = maxSizeBytes;

		try {
			Files.createDirectories(this.fileStorageLocation);
		}
		catch (Exception ex) {
			throw new RuntimeException("Dosya yükleme dizini oluşturulamadı.", ex);
		}
	}

	public String storeFile(MultipartFile file) {
		if (file.isEmpty()) {
			throw new BadRequestException("Boş dosya yüklenemez.");
		}

		// Bulgu #5: Dosya boyutu limiti kontrolü eklendi.
		if (file.getSize() > maxSizeBytes) {
			throw new BadRequestException(
					"Dosya boyutu sınırı aşıldı (Maksimum: " + (maxSizeBytes / 1024 / 1024) + "MB).");
		}

		String originalName = file.getOriginalFilename();
		String extension = originalName != null && originalName.contains(".")
				? originalName.substring(originalName.lastIndexOf(".")) : "";

		String fileName = UUID.randomUUID().toString() + extension;

		String normalizedExtension = extension.toLowerCase();
		if (!ALLOWED_EXTENSIONS.contains(normalizedExtension)) {
			throw new BadRequestException("Desteklenmeyen dosya formatı. Sadece resim ve PDF yüklenebilir.");
		}

		verifyContentMatchesExtension(file, normalizedExtension);

		try {
			Path targetLocation = this.fileStorageLocation.resolve(fileName);
			Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);
			return fileName;
		}
		catch (IOException ex) {
			throw new RuntimeException("Dosya kaydedilemedi: " + fileName, ex);
		}
	}

	/**
	 * Dosyanın ilk baytlarının, adının iddia ettiği türle uyuştuğunu doğrular.
	 */
	private void verifyContentMatchesExtension(MultipartFile file, String extension) {
		byte[] expected = MAGIC_NUMBERS.get(extension);
		byte[] actual = new byte[expected.length];

		try (java.io.InputStream stream = file.getInputStream()) {
			int read = stream.readNBytes(actual, 0, expected.length);
			if (read < expected.length || !java.util.Arrays.equals(expected, actual)) {
				throw new BadRequestException("Dosya içeriği uzantısıyla uyuşmuyor.");
			}
		}
		catch (IOException ex) {
			throw new BadRequestException("Dosya okunamadı.");
		}
	}

	public Resource loadFileAsResource(String fileName) {
		try {
			Path filePath = this.fileStorageLocation.resolve(fileName).normalize();
			if (!filePath.startsWith(this.fileStorageLocation)) {
				throw new BadRequestException("Güvenlik ihlali: Dosya dizini dışına çıkılamaz.");
			}
			Resource resource = new UrlResource(filePath.toUri());

			// Bulgu #1: Merkezi NotFoundException kullanılarak 404 dönmesi sağlandı.
			if (resource.exists()) {
				return resource;
			}
			else {
				throw new NotFoundException("Dosya bulunamadı: " + fileName);
			}
		}
		catch (MalformedURLException ex) {
			throw new NotFoundException("Dosya bulunamadı: " + fileName, ex);
		}
	}

	/**
	 * Verilen adrese karşılık gelen dosyayı diskten siler; hata olursa yalnızca loglar.
	 * <p>
	 * Hesap silmede kullanılır: veritabanı satırını temizlemek yeterli değildir, fotoğraf
	 * dosya sisteminde durmaya devam eder. Silme başarısız olursa asıl işlem (KVKK silme
	 * talebi) geri alınmamalıdır — bu yüzden istisna dışarı sızdırılmaz.
	 * </p>
	 * @param fileUrl {@code /api/v1/files/<ad>} biçiminde tam adres veya doğrudan dosya
	 * adı
	 */
	public void deleteByUrlQuietly(String fileUrl) {
		if (fileUrl == null || fileUrl.isBlank()) {
			return;
		}
		try {
			String fileName = fileUrl.substring(fileUrl.lastIndexOf('/') + 1);
			if (fileName.isBlank() || fileName.contains("..")) {
				return;
			}
			Path target = this.fileStorageLocation.resolve(fileName).normalize();
			// Yol gezinmesine karşı: hedef yükleme klasörünün dışına çıkamaz.
			if (!target.startsWith(this.fileStorageLocation)) {
				log.warn("[FILE] Yükleme klasörü dışına silme denemesi engellendi: {}", fileName);
				return;
			}
			if (Files.deleteIfExists(target)) {
				log.info("[FILE] Dosya silindi: {}", fileName);
			}
		}
		catch (Exception e) {
			log.error("[FILE] Dosya silinemedi: {}", fileUrl, e);
		}
	}

}
