package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.social.dto.CreateReportRequest;
import com.gym.v2.social.entity.ReportReason;
import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import com.gym.v2.social.repository.UserReportRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Sikayet gonderme kurallari.
 */
@ExtendWith(MockitoExtension.class)
class UserReportServiceTest {

	@Mock
	private UserReportRepository userReportRepository;

	@Mock
	private AppUserRepository appUserRepository;

	@Mock
	private UserContextService userContextService;

	private UserReportService service;

	private static final Instant NOW = Instant.parse("2026-09-04T10:00:00Z");

	private AppUser userWithId(Long id) {
		AppUser user = AppUser.builder().email("kullanici@test.com").build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		service = new UserReportService(userReportRepository, appUserRepository, userContextService,
				Clock.fixed(NOW, ZoneOffset.UTC));
		lenient().when(userContextService.getCurrentUser()).thenReturn(userWithId(5L));
	}

	@Test
	void submit_selfReport_isRejectedAndNothingSaved() {
		assertThatThrownBy(() -> service.submit(new CreateReportRequest(5L, ReportReason.SPAM, null)))
			.isInstanceOf(BadRequestException.class);

		verify(userReportRepository, never()).save(any());
	}

	@Test
	void submit_unknownTarget_isRejected() {
		when(appUserRepository.existsById(99L)).thenReturn(false);

		assertThatThrownBy(() -> service.submit(new CreateReportRequest(99L, ReportReason.SPAM, null)))
			.isInstanceOf(NotFoundException.class);

		verify(userReportRepository, never()).save(any());
	}

	/**
	 * Ayni kisiyi ayni sebeple tekrar raporlamak kuyrugu sisirirdi. Karara baglandiktan
	 * SONRA tekrar raporlanabilir; bu test yalnizca BEKLEYEN kaydi engelliyor.
	 */
	@Test
	void submit_duplicatePendingReport_isRejected() {
		when(appUserRepository.existsById(7L)).thenReturn(true);
		when(userReportRepository.existsByReporterIdAndReportedUserIdAndStatus(5L, 7L, ReportStatus.PENDING))
			.thenReturn(true);

		assertThatThrownBy(() -> service.submit(new CreateReportRequest(7L, ReportReason.HARASSMENT, "tekrar")))
			.isInstanceOf(BadRequestException.class);

		verify(userReportRepository, never()).save(any());
	}

	@Test
	void submit_validReport_isSavedAsPendingWithClockTime() {
		when(appUserRepository.existsById(7L)).thenReturn(true);
		when(userReportRepository.existsByReporterIdAndReportedUserIdAndStatus(5L, 7L, ReportStatus.PENDING))
			.thenReturn(false);

		service.submit(new CreateReportRequest(7L, ReportReason.SCAM, "dolandiricilik"));

		ArgumentCaptor<UserReport> captor = ArgumentCaptor.forClass(UserReport.class);
		verify(userReportRepository).save(captor.capture());

		UserReport saved = captor.getValue();
		assertThat(saved.getReporterId()).isEqualTo(5L);
		assertThat(saved.getReportedUserId()).isEqualTo(7L);
		assertThat(saved.getReason()).isEqualTo(ReportReason.SCAM);
		assertThat(saved.getStatus()).isEqualTo(ReportStatus.PENDING);
		assertThat(saved.getCreatedAt()).isEqualTo(NOW);
	}

}
