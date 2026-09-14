package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminOverviewDto;
import com.gym.v2.admin.dto.AdminOverviewProjection;
import com.gym.v2.admin.repository.AdminStatsRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Yonetim panelinin ozet sayilari. Salt okunur.
 */
@Service
public class AdminOverviewService {

	private final AdminStatsRepository adminStatsRepository;

	private final Clock clock;

	public AdminOverviewService(AdminStatsRepository adminStatsRepository, Clock clock) {
		this.adminStatsRepository = adminStatsRepository;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public AdminOverviewDto getOverview() {
		Instant now = clock.instant();

		AdminOverviewProjection p = adminStatsRepository.loadOverview(now.minus(Duration.ofHours(24)),
				now.minus(Duration.ofDays(7)), now.minus(Duration.ofDays(30)),
				LocalDate.ofInstant(now, ZoneOffset.UTC));

		return new AdminOverviewDto(p.getTotalUsers(), p.getClientCount(), p.getCoachCount(), p.getInactiveUsers(),
				p.getNewLast24h(), p.getNewLast7d(), p.getNewLast30d(), p.getActiveLast7d(), p.getPairedClients(),
				p.getActiveSubscriptions());
	}

}
