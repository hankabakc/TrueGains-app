package com.gym.v2.core.security;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * Oturumdaki kullanıcı bilgilerine güvenli erişim sağlayan yardımcı sınıf.
 */
public class SecurityUtils {

	private SecurityUtils() {
		// Yardımcı sınıf, örneklenemez.
	}

	public static String getCurrentUserEmail() {
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication == null || !authentication.isAuthenticated()
				|| authentication instanceof AnonymousAuthenticationToken) {
			return null;
		}

		Object principal = authentication.getPrincipal();
		if (principal instanceof UserDetails userDetails) {
			return userDetails.getUsername();
		}
		if (principal instanceof String s) {
			return s;
		}

		return null;
	}

	public static boolean isAuthenticated() {
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		return authentication != null && authentication.isAuthenticated()
				&& !(authentication instanceof AnonymousAuthenticationToken);
	}

	/**
	 * Authorization başlığından Bearer token'ı güvenli bir şekilde ayıklar.
	 * @param authHeader HTTP isteğinden gelen Authorization başlığı
	 * @return Token varsa kendisi, yoksa null
	 */
	public static String extractToken(String authHeader) {
		if (authHeader != null && authHeader.startsWith(SecurityConstants.BEARER_PREFIX)) {
			return authHeader.substring(SecurityConstants.BEARER_PREFIX.length());
		}
		return null;
	}

}
