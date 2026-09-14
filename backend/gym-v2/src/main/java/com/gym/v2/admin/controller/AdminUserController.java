package com.gym.v2.admin.controller;

import com.gym.v2.admin.dto.AdminUserDetailDto;
import com.gym.v2.admin.dto.AdminUserRowDto;
import com.gym.v2.admin.service.AdminUserService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import java.time.Clock;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Yonetim paneli - kullanicilar.
 */
@RestController
@RequestMapping("/api/v1/admin/users")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

	/** Yonetim listelerinde sayfa boyu ust siniri; istemci daha buyugunu isteyemez. */
	private static final int MAX_PAGE_SIZE = 100;

	private final AdminUserService adminUserService;

	private final Clock clock;

	public AdminUserController(AdminUserService adminUserService, Clock clock) {
		this.adminUserService = adminUserService;
		this.clock = clock;
	}

	@GetMapping
	public ApiResponse<PageResponse<AdminUserRowDto>> search(@RequestParam(required = false) String role,
			@RequestParam(required = false) String query, @RequestParam(required = false) Boolean active,
			@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
		Pageable pageable = PageRequest.of(Math.max(page, 0), Math.clamp(size, 1, MAX_PAGE_SIZE));
		Page<AdminUserRowDto> result = adminUserService.search(role, query, active, pageable);
		return ApiResponse.success(PageResponse.from(result), "Kullanıcılar listelendi.", clock.instant());
	}

	@GetMapping("/{userId}")
	public ApiResponse<AdminUserDetailDto> detail(@PathVariable Long userId) {
		return ApiResponse.success(adminUserService.getDetail(userId), "Kullanıcı getirildi.", clock.instant());
	}

	@PatchMapping("/{userId}/active")
	public ApiResponse<AdminUserDetailDto> setActive(@PathVariable Long userId, @RequestParam boolean value,
			Authentication authentication) {
		AdminUserDetailDto result = adminUserService.setActive(userId, value, authentication.getName());
		return ApiResponse.success(result, value ? "Hesap etkinleştirildi." : "Hesap pasifleştirildi.",
				clock.instant());
	}

}
