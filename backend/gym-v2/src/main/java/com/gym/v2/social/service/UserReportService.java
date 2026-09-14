package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.social.dto.CreateReportRequest;
import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import com.gym.v2.social.repository.UserReportRepository;
import java.time.Clock;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Kullanicinin baska bir kullaniciyi sikayet etmesi.
 */
@Service
public class UserReportService {

	private final UserReportRepository userReportRepository;

	private final AppUserRepository appUserRepository;

	private final UserContextService userContextService;

	private final Clock clock;

	public UserReportService(UserReportRepository userReportRepository, AppUserRepository appUserRepository,
			UserContextService userContextService, Clock clock) {
		this.userReportRepository = userReportRepository;
		this.appUserRepository = appUserRepository;
		this.userContextService = userContextService;
		this.clock = clock;
	}

	@Transactional
	public void submit(CreateReportRequest request) {
		AppUser reporter = userContextService.getCurrentUser();

		if (reporter.getId().equals(request.reportedUserId())) {
			throw new BadRequestException("Kendinizi şikâyet edemezsiniz.");
		}
		if (!appUserRepository.existsById(request.reportedUserId())) {
			throw new NotFoundException("Şikâyet edilen kullanıcı bulunamadı.");
		}

		// Ayni kisiyi ayni sebeple tekrar raporlamak kuyrugu sisirir. Karara
		// baglandiktan SONRA tekrar raporlanabilir; yeni bir olay olabilir.
		if (userReportRepository.existsByReporterIdAndReportedUserIdAndStatus(reporter.getId(),
				request.reportedUserId(), ReportStatus.PENDING)) {
			throw new BadRequestException("Bu kullanıcı için zaten inceleme bekleyen bir şikâyetiniz var.");
		}

		userReportRepository.save(new UserReport(reporter.getId(), request.reportedUserId(), request.reason(),
				request.description(), clock.instant()));
	}

}
