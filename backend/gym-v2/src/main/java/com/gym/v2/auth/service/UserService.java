package com.gym.v2.auth.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * UserService - Manages AppUser data retrieval and core user logic. Adheres to Layered
 * Architecture.
 */
@Service
public class UserService {

	private final AppUserRepository userRepository;

	public UserService(AppUserRepository userRepository) {
		this.userRepository = userRepository;
	}

	@Transactional(readOnly = true)
	public AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı: " + email));
	}

	@Transactional(readOnly = true)
	public AppUser getByEmail(String email) {
		return userRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı: " + email));
	}

}
