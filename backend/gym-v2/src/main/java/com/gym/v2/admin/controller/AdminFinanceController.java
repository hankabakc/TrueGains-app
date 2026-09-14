package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminPaymentRowDto;
import com.gym.v2.admin.dto.AdminRevenueDto;
import com.gym.v2.admin.service.AdminFinanceService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import java.time.Clock;
import java.time.Instant;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Yonetim paneli - gelir ve odemeler. Salt okunur. */
@RestController
@RequestMapping("/api/v1/admin/finance")
@PreAuthorize("hasRole('ADMIN')")
public class AdminFinanceController {

	private static final int MAX_PAGE_SIZE = 100;

	private final AdminFinanceService adminFinanceService;

	private final Clock clock;

	public AdminFinanceController(AdminFinanceService adminFinanceService, Clock clock) {
		this.adminFinanceService = adminFinanceService;
		this.clock = clock;
	}

	@GetMapping("/revenue")
	public ApiResponse<AdminRevenueDto> revenue() {
		return ApiResponse.success(adminFinanceService.getRevenue(), "Gelir özeti getirildi.", clock.instant());
	}

	@GetMapping("/payments")
	public ApiResponse<PageResponse<AdminPaymentRowDto>> payments(@RequestParam(required = false) String status,
			@RequestParam(required = false) String email, @RequestParam(required = false) Instant from,
			@RequestParam(required = false) Instant to, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		Pageable pageable = PageRequest.of(Math.max(page, 0), Math.clamp(size, 1, MAX_PAGE_SIZE));
		return ApiResponse.success(
				PageResponse.from(adminFinanceService.listPayments(status, email, from, to, pageable)),
				"Ödemeler listelendi.", clock.instant());
	}

}
