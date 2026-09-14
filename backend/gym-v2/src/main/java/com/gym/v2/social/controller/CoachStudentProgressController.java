package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.social.dto.CoachStudentProgressDto;
import com.gym.v2.social.dto.CreateProgressRequest;
import com.gym.v2.social.service.CoachStudentProgressService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Clock;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/coaches/progress")
public class CoachStudentProgressController {

	private final CoachStudentProgressService progressService;

	private final Clock clock;

	public CoachStudentProgressController(CoachStudentProgressService progressService, Clock clock) {
		this.progressService = progressService;
		this.clock = clock;
	}

	@PostMapping
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<CoachStudentProgressDto> createProgressRequest(
			@Valid @RequestBody CreateProgressRequest request) {
		return ApiResponse.success(progressService.createProgressRequest(request),
				"Gelişim paylaşım talebi sporcuya gönderildi.", clock.instant());
	}

	@GetMapping("/pending")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<List<CoachStudentProgressDto>> getPendingRequests() {
		return ApiResponse.success(progressService.getPendingRequestsForClient(), "Bekleyen talepler listelendi.",
				clock.instant());
	}

	@PostMapping("/{id}/respond")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<CoachStudentProgressDto> respondToRequest(@PathVariable Long id,
			@RequestBody Map<String, Boolean> response) {
		boolean approved = response.getOrDefault("approved", false);
		String message = approved ? "Gelişim paylaşımı onaylandı." : "Gelişim paylaşımı reddedildi.";
		return ApiResponse.success(progressService.respondToProgressRequest(id, approved), message, clock.instant());
	}

	@GetMapping("/coach/{coachId}/approved")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<CoachStudentProgressDto>> getApprovedProgress(@PathVariable Long coachId) {
		return ApiResponse.success(progressService.getApprovedProgressForCoach(coachId),
				"Onaylanmış gelişimler listelendi.", clock.instant());
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<Void> deleteProgress(@PathVariable Long id) {
		progressService.deleteProgress(id);
		return ApiResponse.success(null, "Gelişim kaydı silindi.", clock.instant());
	}

}
