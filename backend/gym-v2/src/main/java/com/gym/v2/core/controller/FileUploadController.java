package com.gym.v2.core.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.service.FileStorageService;
import java.time.Clock;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;

/**
 * Dosya yükleme ve indirme işlemlerini yöneten denetleyici. Güvenlik iyileştirmeleri
 * (Yetki kontrolü ve XSS koruması) içerir.
 */
@RestController
@RequestMapping("/api/v1/files")
public class FileUploadController {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(FileUploadController.class);

	private final FileStorageService fileStorageService;

	private final Clock clock;

	public FileUploadController(FileStorageService fileStorageService, Clock clock) {
		this.fileStorageService = fileStorageService;
		this.clock = clock;
	}

	/**
	 * Yeni dosya yükler. Onboarding sürecinde kayıtlı olmayan kullanıcıların profil resmi
	 * yükleyebilmesi için erişim yetkisi SecurityConfig üzerinden permitAll() olarak
	 * ayarlanmıştır.
	 */
	@PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
	public ApiResponse<Map<String, String>> uploadFile(@RequestParam("file") MultipartFile file) {
		log.info("[FILE-UPLOAD] Dosya yükleme isteği alındı. Dosya: {}, Boyut: {} bytes", file.getOriginalFilename(),
				file.getSize());
		String fileName = fileStorageService.storeFile(file);

		// Sunucu adı BİLEREK saklanmıyor: adres yükleme anındaki host'a çakılırsa alan
		// adı
		// veya IP değiştiğinde o güne kadarki tüm dosyalar kırılır (bu bir kez yaşandı).
		// Sunucu adını istemci kendi yapılandırmasından ekler (AppConfig.resolveFileUrl).
		String fileDownloadUri = "/api/v1/files/" + fileName;

		log.info("[FILE-UPLOAD] Dosya başarıyla yüklendi. URL: {}", fileDownloadUri);
		return ApiResponse.success(Map.of("url", fileDownloadUri), "Dosya başarıyla yüklendi.", clock.instant());
	}

	/**
	 * Belirtilen dosyayı indirir. Bulgu #3: XSS koruması için Content-Disposition:
	 * attachment zorunlu kılındı.
	 */
	@GetMapping("/{fileName:.+}")
	public ResponseEntity<Resource> downloadFile(@PathVariable String fileName, HttpServletRequest request) {
		Resource resource = fileStorageService.loadFileAsResource(fileName);

		String contentType = request.getServletContext().getMimeType(resource.getFilename());

		if (contentType == null) {
			contentType = "application/octet-stream";
		}

		return ResponseEntity.ok()
			.contentType(MediaType.parseMediaType(contentType))
			.header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
			.body(resource);
	}

}
