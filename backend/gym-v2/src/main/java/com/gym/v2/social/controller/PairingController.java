package com.gym.v2.social.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.response.PageResponse;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.social.dto.CoachDiscoveryDTO;
import com.gym.v2.social.dto.DiscoveryUserDto;
import com.gym.v2.social.service.PairingService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.time.Clock;
import java.util.List;

@RestController
@RequestMapping("/api/v1/social")
public class PairingController {

	private final PairingService pairingService;

	private final Clock clock;

	public PairingController(PairingService pairingService, Clock clock) {
		this.pairingService = pairingService;
		this.clock = clock;
	}

	@GetMapping("/coaches")
	public ApiResponse<PageResponse<CoachDiscoveryDTO>> discoverCoaches(
			@RequestParam(required = false) String specialization, @RequestParam(required = false) String name,
			@RequestParam(required = false) Double minRating, @RequestParam(defaultValue = "rating") String sort,
			Pageable pageable) {
		Page<CoachDiscoveryDTO> response = pairingService.discoverCoaches(specialization, name, minRating, sort,
				pageable);
		return ApiResponse.success(PageResponse.from(response), "Antrenörler başarıyla listelendi.", clock.instant());
	}

	@GetMapping("/discover")
	public ApiResponse<PageResponse<DiscoveryUserDto>> discover(@RequestParam UserRole role, Pageable pageable) {
		Page<DiscoveryUserDto> response = pairingService.discoverUsers(role, pageable);
		return ApiResponse.success(PageResponse.from(response), "Kullanıcılar başarıyla listelendi.", clock.instant());
	}

	// Manuel eşleşme istekleri otomatik eşleşme sistemine geçildiği için devre dışı
	// bırakılmıştır.
	/*
	 * @PostMapping("/pairing/request")
	 *
	 * @PreAuthorize("hasRole('CLIENT')") public ApiResponse<PairingRequestDTO>
	 * sendRequest(@RequestBody @Valid CreatePairingRequest request) { PairingRequestDTO
	 * response = pairingService.sendPairingRequest(request); return
	 * ApiResponse.success(response, "Eşleşme isteği başarıyla gönderildi.",
	 * clock.instant()); }
	 *
	 * @GetMapping("/pairing/pending")
	 *
	 * @PreAuthorize("hasRole('COACH')") public ApiResponse<List<PairingRequestDTO>>
	 * getPendingRequests() { List<PairingRequestDTO> response =
	 * pairingService.getPendingRequestsForCoach(); return ApiResponse.success(response,
	 * "Bekleyen istekler listelendi.", clock.instant()); }
	 *
	 * @PostMapping("/pairing/respond/{requestId}")
	 *
	 * @PreAuthorize("hasRole('COACH')") public ApiResponse<Void>
	 * respondToRequest(@PathVariable Long requestId, @RequestParam boolean accepted) {
	 * pairingService.respondToRequest(requestId, accepted); String message = accepted ?
	 * "Eşleşme isteği onaylandı." : "Eşleşme isteği reddedildi."; return
	 * ApiResponse.success(null, message, clock.instant()); }
	 */

	@GetMapping("/pairing/clients")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<List<DiscoveryUserDto>> getMyClients() {
		List<DiscoveryUserDto> response = pairingService.getMyActiveClients();
		return ApiResponse.success(response, "Aktif öğrencileriniz listelendi.", clock.instant());
	}

}
