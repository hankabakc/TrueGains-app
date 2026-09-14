package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminReportRowDto;
import com.gym.v2.admin.dto.ResolveReportRequest;
import com.gym.v2.admin.service.AdminModerationService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import jakarta.validation.Valid;
import java.time.Clock;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Yonetim paneli - moderasyon kuyrugu. */
@RestController
@RequestMapping("/api/v1/admin/reports")
@PreAuthorize("hasRole('ADMIN')")
public class AdminModerationController {

	private static final int MAX_PAGE_SIZE = 100;

	private final AdminModerationService adminModerationService;

	private final Clock clock;

	public AdminModerationController(AdminModerationService adminModerationService, Clock clock) {
		this.adminModerationService = adminModerationService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<PageResponse<AdminReportRowDto>> search(@RequestParam(required = false) String status,
			@RequestParam(required = false) Long reportedUserId, @RequestParam(defaultValue = "0") int page,
			@RequestParam(defaultValue = "20") int size) {
		Pageable pageable = PageRequest.of(Math.max(page, 0), Math.clamp(size, 1, MAX_PAGE_SIZE));
		return ApiResponse.success(PageResponse.from(adminModerationService.search(status, reportedUserId, pageable)),
				"Şikâyetler listelendi.", clock.instant());
	}

	@PatchMapping("/{reportId}")
	public ApiResponse<AdminReportRowDto> resolve(@PathVariable Long reportId,
			@RequestBody @Valid ResolveReportRequest request, Authentication authentication) {
		// Alan gönderilmediğinde Jackson bu projede ilkel tipe null veremiyor
		// (FAIL_ON_NULL_FOR_PRIMITIVES açık);
		// sarmalayıcı null kalır ve burada false'a indirgenir. Genel ayarı gevşetmek
		// yerine tek alanda çözülüyor.
		AdminReportRowDto result = adminModerationService.resolve(reportId, request.decision(), request.note(),
				Boolean.TRUE.equals(request.suspendReportedUser()), authentication.getName());
		return ApiResponse.success(result, "Şikâyet karara bağlandı.", clock.instant());
	}

}
