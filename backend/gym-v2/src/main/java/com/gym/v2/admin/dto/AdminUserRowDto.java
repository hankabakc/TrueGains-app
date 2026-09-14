package com.gym.v2.admin.dto;

import com.gym.v2.auth.entity.UserRole;
import java.time.Instant;

/**
 * Kullanici listesinde bir satir.
 * <p>
 * Telefon numarasi bilerek YOK: listede bir isi olmayan, en hassas alan. Gerekirse
 * kullanici detayinda gosterilir ve o erisim denetim defterine duser.
 * </p>
 */
public record AdminUserRowDto(Long id, String email, String fullName, UserRole role, boolean active, boolean premium,
		Instant registeredAt, Instant lastLoginAt) {
}
