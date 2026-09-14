package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminUserDetailDto;
import com.gym.v2.admin.repository.AdminReportRepository;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.social.entity.ReportReason;
import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import com.gym.v2.social.repository.UserReportRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Moderasyon kararlari.
 */
@ExtendWith(MockitoExtension.class)
class AdminModerationServiceTest {

	@Mock
	private AdminReportRepository adminReportRepository;

	@Mock
	private UserReportRepository userReportRepository;

	@Mock
	private AdminUserService adminUserService;

	@Mock
	private AuditLogService auditLogService;

	private AdminModerationService service;

	private static final Instant NOW = Instant.parse("2026-09-04T12:00:00Z");

	@BeforeEach
	void setUp() {
		service = new AdminModerationService(adminReportRepository, userReportRepository, adminUserService,
				auditLogService, Clock.fixed(NOW, ZoneOffset.UTC));
	}

	/**
	 * PENDING bir karar degil. Kabul edilseydi bir islemi "geri almanin" yolu olurdu ve
	 * denetim izi bulaniklasirdi.
	 */
	@Test
	void resolve_withPendingDecision_isRejectedBeforeTouchingTheReport() {
		assertThatThrownBy(() -> service.resolve(1L, ReportStatus.PENDING, "not", false, "admin@test.com"))
			.isInstanceOf(BadRequestException.class);

		verify(userReportRepository, never()).findById(any());
		verify(userReportRepository, never()).save(any());
	}

	@Test
	void resolve_unknownReport_isRejected() {
		when(userReportRepository.findById(42L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.resolve(42L, ReportStatus.DISMISSED, null, false, "admin@test.com"))
			.isInstanceOf(NotFoundException.class);
	}

	/**
	 * Karar; durumu, karar vereni ve zamani BIRLIKTE degistirmeli ve ayrica denetim
	 * defterine dusmeli - otomatik erisim kaydi neyin degistigini icermez.
	 */
	@Test
	void resolve_recordsDecisionReviewerTimeAndWritesAudit() {
		UserReport report = new UserReport(5L, 7L, ReportReason.SCAM, "aciklama", NOW.minusSeconds(3600));
		when(userReportRepository.findById(1L)).thenReturn(Optional.of(report));

		service.resolve(1L, ReportStatus.ACTIONED, "hesap pasiflestirildi", false, "admin@test.com");

		assertThat(report.getStatus()).isEqualTo(ReportStatus.ACTIONED);
		assertThat(report.getReviewedBy()).isEqualTo("admin@test.com");
		assertThat(report.getReviewedAt()).isEqualTo(NOW);
		assertThat(report.getResolutionNote()).isEqualTo("hesap pasiflestirildi");

		verify(userReportRepository).save(report);
		verify(auditLogService).log(AdminModerationService.ACTION_RESOLVE, "admin@test.com",
				"reportId=1 decision=ACTIONED reportedUserId=7 suspended=false");
	}

	@Test
	void resolve_suspendReportedUserWithDismissedDecision_throwsBadRequestAndNeverSuspends() {
		assertThatThrownBy(() -> service.resolve(1L, ReportStatus.DISMISSED, "not", true, "admin@test.com"))
			.isInstanceOf(BadRequestException.class)
			.hasMessageContaining("Hesap yalnızca ACTIONED kararıyla pasifleştirilebilir.");

		verify(adminUserService, never()).setActive(anyLong(), anyBoolean(), anyString());
	}

	@Test
	void resolve_suspendReportedUserWithActionedDecisionAndClientTarget_suspendsUserOnce() {
		UserReport report = new UserReport(5L, 7L, ReportReason.HARASSMENT, "taciz", NOW.minusSeconds(3600));
		when(userReportRepository.findById(1L)).thenReturn(Optional.of(report));
		when(adminUserService.getDetail(7L)).thenReturn(userDetailWithRole(7L, UserRole.CLIENT));

		service.resolve(1L, ReportStatus.ACTIONED, "hesap askıya alındı", true, "admin@test.com");

		verify(adminUserService).setActive(7L, false, "admin@test.com");
		verify(auditLogService).log(AdminModerationService.ACTION_RESOLVE, "admin@test.com",
				"reportId=1 decision=ACTIONED reportedUserId=7 suspended=true");
	}

	@Test
	void resolve_withoutSuspendReportedUser_neverCallsSetActive() {
		UserReport report = new UserReport(5L, 7L, ReportReason.SPAM, "spam mesaj", NOW.minusSeconds(3600));
		when(userReportRepository.findById(1L)).thenReturn(Optional.of(report));

		service.resolve(1L, ReportStatus.ACTIONED, "uyarıldı", false, "admin@test.com");

		verify(adminUserService, never()).setActive(anyLong(), anyBoolean(), anyString());
	}

	@Test
	void resolve_suspendReportedUserWithAdminTarget_throwsBadRequestAndNeverSuspends() {
		UserReport report = new UserReport(5L, 99L, ReportReason.OTHER, "sikayet", NOW.minusSeconds(3600));
		when(userReportRepository.findById(1L)).thenReturn(Optional.of(report));
		when(adminUserService.getDetail(99L)).thenReturn(userDetailWithRole(99L, UserRole.ADMIN));

		assertThatThrownBy(
				() -> service.resolve(1L, ReportStatus.ACTIONED, "yonetici sikayeti", true, "admin@test.com"))
			.isInstanceOf(BadRequestException.class)
			.hasMessageContaining("Yönetici hesabı şikâyet üzerinden pasifleştirilemez.");

		verify(adminUserService, never()).setActive(anyLong(), anyBoolean(), anyString());
	}

	private AdminUserDetailDto userDetailWithRole(Long id, UserRole role) {
		return new AdminUserDetailDto(id, "user@test.com", "Ad Soyad", null, role, true, false, NOW, null, 0, null,
				null, null, null, null, null, 0);
	}

}
