package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminErrorsDto;
import com.gym.v2.admin.service.AdminErrorService;
import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Yonetim paneli - hatalar ve cokmeler. */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminErrorController {

	private final AdminErrorService adminErrorService;

	private final Clock clock;

	public AdminErrorController(AdminErrorService adminErrorService, Clock clock) {
		this.adminErrorService = adminErrorService;
		this.clock = clock;
	}

	@GetMapping("/errors")
	public ApiResponse<AdminErrorsDto> errors() {
		return ApiResponse.success(adminErrorService.getErrors(), "Hata özeti getirildi.", clock.instant());
	}

}
