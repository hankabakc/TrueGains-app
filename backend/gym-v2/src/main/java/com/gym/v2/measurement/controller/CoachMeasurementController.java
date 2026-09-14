package com.gym.v2.measurement.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.measurement.dto.ClientMeasurementsSummaryRecord;
import com.gym.v2.measurement.service.MeasurementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.Clock;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Antrenörlerin, sporcuları tarafından paylaşılan ölçümleri görüntülemesini sağlayan API.
 */
@RestController
@RequestMapping("/api/v1/coaches/measurements")
@Tag(name = "Coach Measurement API", description = "Antrenörler için paylaşılan ölçüm görüntüleme operasyonları")
public class CoachMeasurementController {

	private final MeasurementService measurementService;

	private final Clock clock;

	public CoachMeasurementController(MeasurementService measurementService, Clock clock) {
		this.measurementService = measurementService;
		this.clock = clock;
	}

	/**
	 * GET /api/v1/coaches/measurements/shared Antrenöre bağlı sporcuların paylaştığı tüm
	 * ölçümleri döner.
	 */
	@GetMapping("/shared")
	@PreAuthorize("hasRole('COACH')")
	@Operation(summary = "Paylaşılan tüm ölçümleri getir",
			description = "Antrenörün kendisine bağlı sporcuların paylaştığı ölçümleri öğrenci bazlı gruplanmış şekilde getirir.")
	public ApiResponse<List<ClientMeasurementsSummaryRecord>> getSharedMeasurements() {
		List<ClientMeasurementsSummaryRecord> response = measurementService.getSharedMeasurementsForCoach();
		return ApiResponse.success(response, "Paylaşılan ölçümler başarıyla getirildi.", clock.instant());
	}

	/**
	 * GET /api/v1/coaches/measurements/shared/{clientId} Antrenöre bağlı belirli bir
	 * sporcunun paylaştığı ölçümleri döner. IDOR güvenliği: Servis katmanında koç-sporcu
	 * ilişkisi doğrulanır.
	 * @param clientId Sorgulanacak sporcunun ID'si
	 * @return Sporcunun bilgileri ve paylaştığı ölçüm listesi
	 */
	@GetMapping("/shared/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	@Operation(summary = "Tekil sporcu paylaşılan ölçümlerini getir",
			description = "Antrenörün belirli bir sporcusunun paylaştığı ölçümleri getirir.")
	public ApiResponse<ClientMeasurementsSummaryRecord> getSharedMeasurementsForClient(@PathVariable Long clientId) {
		ClientMeasurementsSummaryRecord response = measurementService.getSharedMeasurementsForClient(clientId);
		return ApiResponse.success(response, "Sporcunun paylaşılan ölçümleri başarıyla getirildi.", clock.instant());
	}

}
