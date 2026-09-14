package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminOverviewDto;
import com.gym.v2.admin.service.AdminOverviewService;
import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Yonetim paneli - ozet ekrani.
 * <p>
 * {@code /api/v1/admin/**} yolu SecurityConfig'te ADMIN rolune kilitli. Buradaki
 * {@link PreAuthorize} ikinci savunma hatti: guvenlik yapilandirmasi ileride
 * degistirilirse uc yine korunmasiz kalmaz.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminOverviewController {

	private final AdminOverviewService adminOverviewService;

	private final Clock clock;

	public AdminOverviewController(AdminOverviewService adminOverviewService, Clock clock) {
		this.adminOverviewService = adminOverviewService;
		this.clock = clock;
	}

	@GetMapping("/overview")
	public ApiResponse<AdminOverviewDto> getOverview() {
		return ApiResponse.success(adminOverviewService.getOverview(), "Ozet basariyla getirildi.", clock.instant());
	}

}
