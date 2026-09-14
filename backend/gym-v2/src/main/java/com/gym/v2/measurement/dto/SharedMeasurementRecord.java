package com.gym.v2.measurement.dto;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Antrenörle paylaşılan tekil bir ölçüm kaydı.
 */
public record SharedMeasurementRecord(Long id, BigDecimal weight, BigDecimal height, BigDecimal bodyFatPct,
		BigDecimal muscleMass, BigDecimal chest, BigDecimal waist, BigDecimal shoulders, BigDecimal leftArm,
		BigDecimal rightArm, BigDecimal leftLeg, BigDecimal rightLeg, BigDecimal hips, String notes,
		Instant measurementDate) {
}
