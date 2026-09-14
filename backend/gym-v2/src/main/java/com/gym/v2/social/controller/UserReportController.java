package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.social.dto.CreateReportRequest;
import com.gym.v2.social.entity.ReportReason;
import com.gym.v2.social.service.UserReportService;
import jakarta.validation.Valid;
import java.time.Clock;
import java.util.Arrays;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Kullanici sikayetleri (uygulama tarafi).
 * <p>
 * Yonetim ucu ayri: {@code /api/v1/admin/reports}. Sikayet EDEN kendi kaydini bile geri
 * okuyamiyor - kimin kimi sikayet ettigi bilgisi yalnizca yonetimde.
 * </p>
 */
@RestController
@RequestMapping("/api/v1/social/reports")
public class UserReportController {

	private final UserReportService userReportService;

	private final Clock clock;

	public UserReportController(UserReportService userReportService, Clock clock) {
		this.userReportService = userReportService;
		this.clock = clock;
	}

	@PostMapping
	public ApiResponse<Void> submit(@RequestBody @Valid CreateReportRequest request) {
		userReportService.submit(request);
		return ApiResponse.success(null, "Şikâyetiniz alındı, en kısa sürede incelenecek.", clock.instant());
	}

	@GetMapping("/reasons")
	public ApiResponse<List<ReportReason>> reasons() {
		return ApiResponse.success(Arrays.asList(ReportReason.values()), "Şikâyet sebepleri.", clock.instant());
	}

}
