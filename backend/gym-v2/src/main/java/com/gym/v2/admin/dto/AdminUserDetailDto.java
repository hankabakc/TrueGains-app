package com.gym.v2.admin.dto;

import com.gym.v2.auth.entity.UserRole;
import java.time.Instant;

/**
 * Tek kullanicinin ayrintisi.
 * <p>
 * Bu uc kisisel veri (ad, telefon) dondurur; {@code AdminAuditInterceptor} her cagriyi
 * kaydeder, yani "kim kimin verisine bakti" sorusu cevaplanabilir kalir.
 * </p>
 */
public record AdminUserDetailDto(Long id, String email, String fullName, String phoneNumber, UserRole role,
		boolean active, boolean premium, Instant registeredAt, Instant lastLoginAt, Integer failedLoginAttempts,
		Instant accountLockedUntil, String province, String district, Integer experienceYears, String specialization,
		Long coachId, long activeSubscriptions) {
}
