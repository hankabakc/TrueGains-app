package com.gym.v2.social.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.service.UserService;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.social.service.CoachRequestService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import java.time.Clock;

/**
 * Sporcuların (Client) çeşitli isteklerini yöneten API katmanı.
 */
// @RestController
// @RequestMapping("/api/v1/clients/requests")
public class ClientRequestController {

	private final CoachRequestService coachRequestService;

	private final UserService userService;

	private final Clock clock;

	/**
	 * Constructor injection.
	 */
	public ClientRequestController(CoachRequestService coachRequestService, UserService userService, Clock clock) {
		this.coachRequestService = coachRequestService;
		this.userService = userService;
		this.clock = clock;
	}

	/**
	 * Mevcut sporcudan bir antrenöre koçluk isteği gönderir.
	 * @param coachId Hedef antrenörün ID'si
	 * @return Başarı durumunu içeren ApiResponse
	 */
	@PostMapping("/coach/{coachId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> sendCoachRequest(@PathVariable Long coachId) {
		AppUser currentUser = userService.getCurrentUser();
		coachRequestService.sendRequestToCoach(currentUser.getId(), coachId);
		return ApiResponse.success(null, "Koçluk isteği başarıyla gönderildi.", clock.instant());
	}

}
