package com.gym.v2.measurement.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import com.gym.v2.measurement.dto.MeasurementDTO;
import com.gym.v2.measurement.service.MeasurementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import java.time.Clock;
import org.springframework.web.bind.annotation.*;

/**
 * GYMAPP-V2 Ölçüm API Controller'ı. Kullanıcıların vücut ölçümlerini eklemesini,
 * listelemesini ve silmesini sağlayan REST endpoint'leri sunar.
 */
@RestController
@RequestMapping("/api/v1/measurements")
@Tag(name = "Measurement API", description = "Vücut ölçüm takip operasyonları")
public class MeasurementController {

	private final MeasurementService measurementService;

	private final Clock clock;

	// Constructor Injection (Anayasa Kuralı: @Autowired yasak)
	public MeasurementController(MeasurementService measurementService, Clock clock) {
		this.measurementService = measurementService;
		this.clock = clock;
	}

	/**
	 * POST /api/v1/measurements Yeni ölçüm kaydı oluşturur.
	 */
	@PostMapping
	@PreAuthorize("hasRole('CLIENT')")
	@Operation(summary = "Yeni ölçüm kaydet", description = "Sadece bilinen ölçülerin gönderilmesi yeterlidir.")
	public ApiResponse<MeasurementDTO> addMeasurement(@Valid @RequestBody MeasurementDTO request) {
		MeasurementDTO response = measurementService.addMeasurement(request);
		return ApiResponse.success(response, "Ölçüm başarıyla kaydedildi.", clock.instant());
	}

	/**
	 * GET /api/v1/measurements Oturum açmış kullanıcının tüm ölçüm geçmişini sayfalama
	 * desteği ile döner.
	 */
	@GetMapping
	@PreAuthorize("hasRole('CLIENT')")
	@Operation(summary = "Ölçüm geçmişini getir",
			description = "Oturum açmış kullanıcının tüm kayıtlarını sayfalama ile döner.")
	public ApiResponse<com.gym.v2.core.response.PageResponse<MeasurementDTO>> getMyMeasurements(
			@ParameterObject Pageable pageable) {
		Page<MeasurementDTO> response = measurementService.getMyMeasurements(pageable);
		return ApiResponse.success(com.gym.v2.core.response.PageResponse.from(response), "Ölçüm geçmişi listelendi.",
				clock.instant());
	}

	/**
	 * GET /api/v1/measurements/today Bugün girilmiş bir ölçüm varsa döner, yoksa null
	 * döner.
	 */
	@GetMapping("/today")
	@PreAuthorize("hasRole('CLIENT')")
	@Operation(summary = "Bugünkü ölçümü sorgula", description = "Bugün girilmiş kayıt varsa döner, yoksa null döner.")
	public ApiResponse<MeasurementDTO> getTodayMeasurement() {
		MeasurementDTO response = measurementService.getTodayMeasurement();
		return ApiResponse.success(response, "Bugünkü ölçüm durumu sorgulandı.", clock.instant());
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasRole('CLIENT')")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	@Operation(summary = "Ölçüm sil", description = "Kullanıcı yalnızca kendi ölçüm kaydını silebilir.")
	public ApiResponse<Void> deleteMeasurement(@PathVariable Long id) {
		measurementService.deleteMeasurement(id);
		return ApiResponse.success(null, "Ölçüm kaydı silindi.", clock.instant());
	}

	/**
	 * GET /api/v1/measurements/client/{clientId} Koçun, sporcusuna ait ölçüm geçmişini
	 * görmesini sağlar.
	 */
	@GetMapping("/client/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	@Operation(summary = "Sporcu ölçüm geçmişini getir",
			description = "Koçun, kendi aktif öğrencisinin ölçümlerini görmesini sağlar.")
	public ApiResponse<PageResponse<MeasurementDTO>> getClientMeasurements(@PathVariable Long clientId,
			@ParameterObject Pageable pageable) {
		Page<MeasurementDTO> response = measurementService.getClientMeasurements(clientId, pageable);
		return ApiResponse.success(PageResponse.from(response), "Sporcu ölçüm geçmişi listelendi.", clock.instant());
	}

	/**
	 * POST /api/v1/measurements/share Seçilen ölçümleri antrenörle paylaşır.
	 */
	@PostMapping("/share")
	@PreAuthorize("hasRole('CLIENT')")
	@Operation(summary = "Ölçümleri antrenörle paylaş",
			description = "Seçilen ölçüm ID'lerini antrenörün görebileceği şekilde işaretler.")
	public ApiResponse<Void> shareMeasurements(@RequestBody java.util.List<Long> measurementIds) {
		measurementService.shareMeasurementsWithCoach(measurementIds);
		return ApiResponse.success(null, "Ölçümler başarıyla paylaşıldı.", clock.instant());
	}

}
