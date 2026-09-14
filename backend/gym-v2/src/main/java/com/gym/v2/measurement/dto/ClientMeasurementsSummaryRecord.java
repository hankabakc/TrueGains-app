package com.gym.v2.measurement.dto;

import java.util.List;

/**
 * Antrenörün görüntülediği, öğrenci bazlı gruplandırılmış ölçüm özeti.
 */
public record ClientMeasurementsSummaryRecord(Long clientId, String clientName,
		List<SharedMeasurementRecord> measurements) {
}
