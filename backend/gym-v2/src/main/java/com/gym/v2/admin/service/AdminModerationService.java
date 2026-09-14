package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminReportRowDto;
import com.gym.v2.admin.repository.AdminReportRepository;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import com.gym.v2.social.repository.UserReportRepository;
import java.time.Clock;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Moderasyon kuyrugu. */
@Service
public class AdminModerationService {

	static final String ACTION_RESOLVE = "ADMIN_REPORT_RESOLVE";

	private final AdminReportRepository adminReportRepository;

	private final UserReportRepository userReportRepository;

	private final AdminUserService adminUserService;

	private final AuditLogService auditLogService;

	private final Clock clock;

	public AdminModerationService(AdminReportRepository adminReportRepository,
			UserReportRepository userReportRepository, AdminUserService adminUserService,
			AuditLogService auditLogService, Clock clock) {
		this.adminReportRepository = adminReportRepository;
		this.userReportRepository = userReportRepository;
		this.adminUserService = adminUserService;
		this.auditLogService = auditLogService;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public Page<AdminReportRowDto> search(String status, Long reportedUserId, Pageable pageable) {
		String normalized = (status == null || status.isBlank()) ? null : status;

		return adminReportRepository.search(normalized, reportedUserId, pageable).map(row -> {
			UserReport r = (UserReport) row[0];
			return toRow(r, (String) row[1], (String) row[2]);
		});
	}

	/**
	 * Sikayeti karara baglar.
	 * <p>
	 * {@code PENDING} bir karar degil: kuyruktan cikarmadan "beklemede" yazmak islemi
	 * geri almanin yolu olurdu ve denetim izini bulanistirirdi.
	 * </p>
	 */
	@Transactional
	public AdminReportRowDto resolve(Long reportId, ReportStatus decision, String note, boolean suspendReportedUser,
			String adminEmail) {
		if (decision == ReportStatus.PENDING) {
			throw new BadRequestException("Karar ACTIONED veya DISMISSED olmalıdır.");
		}
		// Reddedilen şikâyet + askıya alınan hesap çelişkili bir kayıttır;
		// denetim defterinde neden askıya alındığı okunamaz hâle gelir.
		if (suspendReportedUser && decision != ReportStatus.ACTIONED) {
			throw new BadRequestException("Hesap yalnızca ACTIONED kararıyla pasifleştirilebilir.");
		}

		UserReport report = userReportRepository.findById(reportId)
			.orElseThrow(() -> new NotFoundException("Şikâyet bulunamadı."));

		report.resolve(decision, adminEmail, note, clock.instant());
		userReportRepository.save(report);

		if (suspendReportedUser) {
			// Yöneticiyi şikâyet üzerinden kapatmak mümkün olmamalı: tek yönetici
			// hesabı varsa panel tamamen erişilemez hâle gelir.
			if (adminUserService.getDetail(report.getReportedUserId()).role() == UserRole.ADMIN) {
				throw new BadRequestException("Yönetici hesabı şikâyet üzerinden pasifleştirilemez.");
			}
			adminUserService.setActive(report.getReportedUserId(), false, adminEmail);
		}

		auditLogService.log(ACTION_RESOLVE, adminEmail, "reportId=" + reportId + " decision=" + decision
				+ " reportedUserId=" + report.getReportedUserId() + " suspended=" + suspendReportedUser);

		return toRow(report, null, null);
	}

	private AdminReportRowDto toRow(UserReport r, String reporterEmail, String reportedEmail) {
		return new AdminReportRowDto(r.getId(), r.getReporterId(), reporterEmail, r.getReportedUserId(), reportedEmail,
				r.getReason(), r.getDescription(), r.getStatus(), r.getCreatedAt(), r.getReviewedAt(),
				r.getReviewedBy(), r.getResolutionNote(),
				userReportRepository.countByReportedUser(r.getReportedUserId(), ReportStatus.PENDING));
	}

}
