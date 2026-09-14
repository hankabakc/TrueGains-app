package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminAuditRowDto;
import com.gym.v2.admin.service.AdminAuditService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import java.time.Clock;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Yonetim paneli - denetim defteri.
 * <p>
 * Yalnizca GET var. Denetim kaydini silen ya da degistiren bir uc, kaydin kendisini
 * degersiz kilardi.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/admin/audit")
@PreAuthorize("hasRole('ADMIN')")
public class AdminAuditController {

	private static final int MAX_PAGE_SIZE = 200;

	private final AdminAuditService adminAuditService;

	private final Clock clock;

	public AdminAuditController(AdminAuditService adminAuditService, Clock clock) {
		this.adminAuditService = adminAuditService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<PageResponse<AdminAuditRowDto>> search(@RequestParam(required = false) String action,
			@RequestParam(required = false) String email, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "50") int size) {
		Pageable pageable = PageRequest.of(Math.max(page, 0), Math.clamp(size, 1, MAX_PAGE_SIZE));
		return ApiResponse.success(PageResponse.from(adminAuditService.search(action, email, pageable)),
				"Denetim kayıtları listelendi.", clock.instant());
	}

	@GetMapping("/actions")
	public ApiResponse<List<String>> actions() {
		return ApiResponse.success(adminAuditService.actions(), "Eylem türleri getirildi.", clock.instant());
	}

}
