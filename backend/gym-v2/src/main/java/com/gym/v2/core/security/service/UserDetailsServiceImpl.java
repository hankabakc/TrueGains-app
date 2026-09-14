package com.gym.v2.core.security.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.util.Collections;

/**
 * Spring Security için kullanıcı bilgilerini veritabanından yükleyen servis. Güvenlik
 * iyileştirmeleri (Enumeration koruması ve Hesap Durumu) içerir.
 */
@Service
public class UserDetailsServiceImpl implements UserDetailsService {

	private final AppUserRepository userRepository;

	private final Clock clock;

	public UserDetailsServiceImpl(AppUserRepository userRepository, Clock clock) {
		this.userRepository = userRepository;
		this.clock = clock;
	}

	@Override
	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
		AppUser user = userRepository.findByEmail(username).orElseThrow(() -> {
			// Güvenlik Bulgu #2: Kullanıcı e-postası hata mesajına dahil edilmez
			// (Enumeration Protection).
			return new UsernameNotFoundException("Kimlik doğrulama başarısız.");
		});

		// Güvenlik Bulgu #3: Hesap aktifliği ve kilitleme durumu kontrol ediliyor.
		boolean isLocked = user.getAccountLockedUntil() != null
				&& user.getAccountLockedUntil().isAfter(clock.instant());

		return new CustomUserDetails(user.getId(), user.getEmail(), user.getPassword(),
				Boolean.TRUE.equals(user.getIsActive()), true, true, !isLocked,
				Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + user.getRole())));
	}

}
