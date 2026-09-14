package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.social.dto.*;
import com.gym.v2.social.service.CoachProfileService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import java.time.Clock;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/coaches")
public class CoachProfileController {

	private final CoachProfileService coachProfileService;

	private final Clock clock;

	public CoachProfileController(CoachProfileService coachProfileService, Clock clock) {
		this.coachProfileService = coachProfileService;
		this.clock = clock;
	}

	@GetMapping("/{id}/profile")
	public ApiResponse<CoachProfileResponse> getCoachProfile(@PathVariable Long id) {
		CoachProfileResponse profile = coachProfileService.getCoachProfile(id);
		return ApiResponse.success(profile, "Profile retrieved", clock.instant());
	}

	@GetMapping("/{id}/reviews")
	public ApiResponse<Page<CoachReviewDto>> getCoachReviews(@PathVariable Long id,
			@PageableDefault(size = 20) Pageable pageable) {
		Page<CoachReviewDto> reviews = coachProfileService.getReviews(id, pageable);
		return ApiResponse.success(reviews, "Reviews retrieved", clock.instant());
	}

	@PostMapping("/{id}/reviews")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<CoachReviewDto> addReview(@PathVariable Long id, @RequestBody @Valid AddReviewRequest request) {
		CoachReviewDto review = coachProfileService.addReview(id, request.rating(), request.comment());
		return ApiResponse.success(review, "Review submitted successfully", clock.instant());
	}

	@PostMapping("/gallery")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<CoachGalleryDto> addGalleryItem(@RequestBody @Valid AddGalleryItemRequest request) {
		CoachGalleryDto item = coachProfileService.addGalleryItem(request);
		return ApiResponse.success(item, "Galeri öğesi başarıyla eklendi.", clock.instant());
	}

	@DeleteMapping("/gallery/{itemId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<Void> deleteGalleryItem(@PathVariable Long itemId) {
		coachProfileService.deleteGalleryItem(itemId);
		return ApiResponse.success(null, "Galeri öğesi başarıyla silindi.", clock.instant());
	}

}
