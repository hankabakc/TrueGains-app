package com.gym.v2.nutrition.dto;

import java.time.Instant;

/**
 * Koçun diyet şablonu atamalarını yönetirken, hangi sporcuya hangi program kopyasının
 * atandığını gösteren veri transfer nesnesidir (DTO).
 */
public record DietAssignmentResponse(Long assignmentId, UserSummary user, DietProgramSummary dietProgram,
		String status) {
	public record UserSummary(Long id, String firstName, String lastName, String profilePhotoUrl) {
	}

	public record DietProgramSummary(Long id, String name, Instant startDate, Instant endDate) {
	}
}
