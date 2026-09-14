package com.gym.v2.membership.controller;

import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.membership.dto.*;
import com.gym.v2.membership.service.AccountDeletionService;
import com.gym.v2.membership.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.Clock;

@RestController
@RequestMapping("/api/v1/profile")
public class ProfileController {

	private final ProfileService profileService;

	private final AccountDeletionService accountDeletionService;

	private final Clock clock;

	public ProfileController(ProfileService profileService, AccountDeletionService accountDeletionService,
			Clock clock) {
		this.profileService = profileService;
		this.accountDeletionService = accountDeletionService;
		this.clock = clock;
	}

	/**
	 * Kullanıcının kendi hesabını silmesi (KVKK m.7; Apple/Google mağaza şartı).
	 * <p>
	 * Hedef her zaman oturum açmış kullanıcıdır — başka bir hesabı silmenin yolu yoktur,
	 * bu yüzden uçta kimlik parametresi de yoktur.
	 * </p>
	 */
	@DeleteMapping("/me")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<Void> deleteMyAccount() {
		accountDeletionService.deleteMyAccount();
		return ApiResponse.success(null, "Hesabınız ve kişisel verileriniz silindi.", clock.instant());
	}

	@GetMapping("/client/me")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<ClientProfileResponse> getMyProfile() {
		return ApiResponse.success(profileService.getMyProfile(), "Profil bilgileri getirildi.", clock.instant());
	}

	@GetMapping("/coach/me")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<CoachProfileResponse> getMyCoachProfile() {
		return ApiResponse.success(profileService.getMyCoachProfile(), "Antrenör profil bilgileri getirildi.",
				clock.instant());
	}

	@PutMapping("/client/{userId}")
	@PreAuthorize("hasRole('CLIENT')")
	public ApiResponse<Void> updateClientProfile(@PathVariable Long userId,
			@Valid @RequestBody ClientProfileRequest request) {
		profileService.updateClientProfile(userId, request);
		return ApiResponse.success(null, "Sporcu profili başarıyla güncellendi.", clock.instant());
	}

	@PutMapping("/coach/{userId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<Void> updateCoachProfile(@PathVariable Long userId,
			@Valid @RequestBody CoachProfileRequest request) {
		profileService.updateCoachProfile(userId, request);
		return ApiResponse.success(null, "Antrenör profili başarıyla güncellendi.", clock.instant());
	}

	@PostMapping("/change-password")
	@PreAuthorize("hasAnyRole('CLIENT', 'COACH')")
	public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
		profileService.changePassword(request);
		return ApiResponse.success(null, "Şifre başarıyla değiştirildi.", clock.instant());
	}

	@GetMapping("/client/{clientId}")
	@PreAuthorize("hasRole('COACH')")
	public ApiResponse<ClientProfileResponse> getClientProfileForCoach(@PathVariable Long clientId) {
		return ApiResponse.success(profileService.getClientProfileForCoach(clientId),
				"Sporcu profil bilgileri antrenör için getirildi.", clock.instant());
	}

}
