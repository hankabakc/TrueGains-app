package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.social.dto.ClientGalleryDto;
import com.gym.v2.social.service.ClientGalleryService;
import org.springframework.web.bind.annotation.*;

import java.time.Clock;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/clients/gallery")
public class ClientGalleryController {

	private final ClientGalleryService galleryService;

	private final Clock clock;

	public ClientGalleryController(ClientGalleryService galleryService, Clock clock) {
		this.galleryService = galleryService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<List<ClientGalleryDto>> getMyGallery() {
		return ApiResponse.success(galleryService.getMyGallery(), "Galeri başarıyla listelendi.", clock.instant());
	}

	@PostMapping
	public ApiResponse<ClientGalleryDto> addToGallery(@RequestBody Map<String, String> request) {
		String imageUrl = request.get("imageUrl");
		return ApiResponse.success(galleryService.addToGallery(imageUrl), "Resim galerinize eklendi.", clock.instant());
	}

	@DeleteMapping("/{id}")
	public ApiResponse<Void> deleteGalleryItem(@PathVariable Long id) {
		galleryService.deleteGalleryItem(id);
		return ApiResponse.success(null, "Resim galerinizden silindi.", clock.instant());
	}

}
