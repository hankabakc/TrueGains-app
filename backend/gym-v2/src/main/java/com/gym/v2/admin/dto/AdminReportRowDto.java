package com.gym.v2.admin.dto;

import com.gym.v2.social.entity.ReportReason;
import com.gym.v2.social.entity.ReportStatus;
import java.time.Instant;

/** Moderasyon kuyrugunda bir satir. */
public record AdminReportRowDto(Long id, Long reporterId, String reporterEmail, Long reportedUserId,
		String reportedEmail, ReportReason reason, String description, ReportStatus status, Instant createdAt,
		Instant reviewedAt, String reviewedBy, String resolutionNote, long reportedUserPendingCount) {
}
