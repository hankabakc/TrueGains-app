package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminSystemDto;
import com.gym.v2.admin.service.AdminSystemService;
import com.gym.v2.core.response.ApiResponse;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Yonetim paneli - sunucu durumu.
 * <p>
 * Actuator uclari bilerek yonetim portunda (9090) kapali kaliyor; panel bu uc uzerinden
 * yalnizca SECILMIS sayilari goruyor. Actuator'u API portuna acmak butun calisma zamani
 * bilgisini disariya sermek olurdu.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminSystemController {

	private final AdminSystemService adminSystemService;

	private final Clock clock;

	public AdminSystemController(AdminSystemService adminSystemService, Clock clock) {
		this.adminSystemService = adminSystemService;
		this.clock = clock;
	}

	@GetMapping("/system")
	public ApiResponse<AdminSystemDto> getSystemStatus() {
		return ApiResponse.success(adminSystemService.getSystemStatus(), "Sistem durumu getirildi.", clock.instant());
	}

}
