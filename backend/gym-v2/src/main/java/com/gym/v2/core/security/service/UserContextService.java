package com.gym.v2.core.security.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

/**
 * Mevcut oturum açmış kullanıcıya erişim sağlayan merkezi servis.
 */
@Service
public class UserContextService {

	private final AppUserRepository userRepository;

	public UserContextService(AppUserRepository userRepository) {
		this.userRepository = userRepository;
	}

	/**
	 * Mevcut oturum açmış kullanıcıyı döndürür.
	 * @return AppUser
	 * @throws NotFoundException Kullanıcı bulunamazsa
	 */
	public AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

	/**
	 * Mevcut oturum açmış kullanıcının ID'sini döndürür. Veritabanı sorgusu atmadan
	 * doğrudan SecurityContext üzerinden okuma yapar.
	 * @return Long
	 * @throws NotFoundException Kullanıcı ID bulunamazsa
	 */
	public Long getCurrentUserId() {
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication != null && authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
			return userDetails.getId();
		}

		// Fallback: Eğer context'te yoksa email üzerinden sorgula (B-PERF-2 optimizasyonu
		// korunur)
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findIdByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı ID bulunamadı."));
	}

}
