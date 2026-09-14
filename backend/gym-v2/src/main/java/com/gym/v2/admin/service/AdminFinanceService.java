package com.gym.v2.admin.service;

import com.gym.v2.admin.dto.AdminPaymentRowDto;
import com.gym.v2.admin.dto.AdminRevenueDto;
import com.gym.v2.admin.dto.AdminRevenueProjection;
import com.gym.v2.admin.repository.AdminFinanceRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Gelir ve odeme okumalari. */
@Service
public class AdminFinanceService {

	/** Süzgeç verilmeyen uç. Sorguya null an gönderilmez: bkz. AdminFinanceRepository. */
	private static final Instant NO_LOWER_BOUND = Instant.EPOCH;

	private static final Instant NO_UPPER_BOUND = Instant.parse("9999-12-31T23:59:59Z");

	private final AdminFinanceRepository adminFinanceRepository;

	private final Clock clock;

	public AdminFinanceService(AdminFinanceRepository adminFinanceRepository, Clock clock) {
		this.adminFinanceRepository = adminFinanceRepository;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public AdminRevenueDto getRevenue() {
		Instant now = clock.instant();
		LocalDate today = LocalDate.ofInstant(now, ZoneOffset.UTC);

		AdminRevenueProjection p = adminFinanceRepository.loadSummary(now.minus(Duration.ofHours(24)),
				now.minus(Duration.ofDays(7)), now.minus(Duration.ofDays(30)), today, today.plusDays(7));

		return new AdminRevenueDto(p.getRevenueToday(), p.getRevenue7d(), p.getRevenue30d(), p.getRevenueTotal(),
				p.getSuccessfulPayments(), p.getFailedPayments(), p.getActiveSubscriptions(), p.getExpiringIn7d());
	}

	@Transactional(readOnly = true)
	public Page<AdminPaymentRowDto> listPayments(String status, String email, Instant from, Instant to,
			Pageable pageable) {
		boolean hasRange = from != null || to != null;

		return adminFinanceRepository
			.listPayments(blankToNull(status), blankToNull(email), hasRange, from == null ? NO_LOWER_BOUND : from,
					to == null ? NO_UPPER_BOUND : to, pageable)
			.map(p -> new AdminPaymentRowDto(p.getId(), p.getClientEmail(), p.getAmount(), p.getStatus(),
					ProjectionTime.toInstant(p.getTransactionDate()), p.getPackageName()));
	}

	private static String blankToNull(String value) {
		return (value == null || value.isBlank()) ? null : value;
	}

}
