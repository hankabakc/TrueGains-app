package com.gym.v2.nutrition.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.nutrition.dto.ClientWaterTrackingResponse;
import com.gym.v2.nutrition.service.CoachWaterTrackingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.util.List;

/**
 * CoachWaterTrackingController - Antrenörlerin öğrencilerine ait su tüketim ve
 * hedeflerini okumasını sağlayan API katmanı. PreAuthorize ile yetkisiz erişimler
 * engellenmiştir. Lombok yasak olup sadece Constructor Injection kullanılmıştır.
 */
@RestController
@RequestMapping("/api/v1/coach/students/water-intake")
@Tag(name = "Coach Water Tracking API", description = "Antrenörler için öğrencilerin su tüketim takibi operasyonları")
public class CoachWaterTrackingController {

	private final CoachWaterTrackingService waterTrackingService;

	private final Clock clock;

	/**
	 * Constructor injection ile bağımlılıklar alınır.
	 */
	public CoachWaterTrackingController(CoachWaterTrackingService waterTrackingService, Clock clock) {
		this.waterTrackingService = waterTrackingService;
		this.clock = clock;
	}

	/**
	 * GET /api/v1/coach/students/water-intake Sadece COACH rolündeki antrenörlerin
	 * kendisine bağlı sporcuların günlük su verilerini çekmesini sağlar.
	 * @return ApiResponse<List<ClientWaterTrackingResponse>> Öğrencilerin su bilgileri
	 */
	@GetMapping
	@PreAuthorize("hasRole('COACH')")
	@Operation(summary = "Öğrencilerin günlük su tüketimlerini getir",
			description = "Koça bağlı öğrencilerin günlük su tüketim hedeflerini ve o gün içtikleri su miktarlarını listeler.")
	public ApiResponse<List<ClientWaterTrackingResponse>> getStudentsWaterIntake() {
		List<ClientWaterTrackingResponse> trackingData = waterTrackingService.getStudentsWaterIntake();
		return ApiResponse.success(trackingData, "Öğrencilerin günlük su tüketim verileri başarıyla getirildi.",
				clock.instant());
	}

	@GetMapping("/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	@Operation(summary = "Belirli bir öğrencinin günlük su tüketimini getir",
			description = "Koça bağlı bir öğrencinin günlük su tüketim hedefini ve o gün içtiği su miktarını getirir.")
	public ApiResponse<ClientWaterTrackingResponse> getStudentWaterIntake(@PathVariable Long clientId) {
		ClientWaterTrackingResponse trackingData = waterTrackingService.getStudentWaterIntake(clientId);
		return ApiResponse.success(trackingData, "Öğrencinin su tüketim verisi başarıyla getirildi.", clock.instant());
	}

}
