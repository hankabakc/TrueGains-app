package com.gym.v2.auth.controller;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.entity.UserDeviceToken;
import com.gym.v2.auth.repository.UserDeviceTokenRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.response.ApiResponse;
import com.gym.v2.core.security.SecurityUtils;
import java.time.Clock;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Kullanıcı hesap işlemlerini yöneten denetleyici.
 */
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

	private final AppUserRepository userRepository;

	private final UserDeviceTokenRepository deviceTokenRepository;

	private final Clock clock;

	public UserController(AppUserRepository userRepository, UserDeviceTokenRepository deviceTokenRepository,
			Clock clock) {
		this.userRepository = userRepository;
		this.deviceTokenRepository = deviceTokenRepository;
		this.clock = clock;
	}

	/**
	 * Mevcut kullanıcının FCM cihaz token'ını günceller.
	 * @param token Cihaz token'ı.
	 * @return İşlem sonucu.
	 */
	@PostMapping("/device-token")
	@PreAuthorize("isAuthenticated()")
	public ApiResponse<Void> updateDeviceToken(@RequestBody String token) {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser user = userRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		// Token ayrı tabloda tutulur: kullanıcı birden çok cihazdan girebilir ve tek
		// alanda tutulduğunda ikinci giriş birincinin bildirimlerini kesiyordu.
		// Aynı token başka bir hesaba bağlıysa devralınır — cihaz el değiştirmiş demektir
		// ve eski sahibin bildirimleri yeni kullanıcıya gitmemelidir.
		String normalized = token == null ? "" : token.trim().replace("\"", "");
		if (normalized.isBlank()) {
			throw new BadRequestException("Cihaz token'ı boş olamaz.");
		}
		deviceTokenRepository.findByToken(normalized).ifPresent(deviceTokenRepository::delete);
		deviceTokenRepository.saveAndFlush(new UserDeviceToken(user, normalized, clock.instant()));

		return ApiResponse.success(null, "Cihaz token'ı başarıyla güncellendi.", clock.instant());
	}

}
