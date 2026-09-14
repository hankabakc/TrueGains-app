package com.gym.v2.core.security.filter;

import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.service.JwtService;
import com.gym.v2.core.security.service.UserDetailsServiceImpl;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import java.time.Clock;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gym.v2.core.response.ApiResponse;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import org.springframework.http.MediaType;

import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

	private final JwtService jwtService;

	private final UserDetailsServiceImpl userDetailsService;

	private final BlacklistedTokenRepository blacklistedTokenRepository;

	private final ObjectMapper objectMapper;

	private final Clock clock;

	public JwtAuthenticationFilter(JwtService jwtService, UserDetailsServiceImpl userDetailsService,
			BlacklistedTokenRepository blacklistedTokenRepository, ObjectMapper objectMapper, Clock clock) {
		this.jwtService = jwtService;
		this.userDetailsService = userDetailsService;
		this.blacklistedTokenRepository = blacklistedTokenRepository;
		this.objectMapper = objectMapper;
		this.clock = clock;
	}

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {
		final String authHeader = request.getHeader(SecurityConstants.AUTH_HEADER);
		final String jwt;
		final String userEmail;

		jwt = SecurityUtils.extractToken(authHeader);
		if (jwt == null) {
			filterChain.doFilter(request, response);
			return;
		}

		try {

			// Kara Liste Kontrolü (JTI üzerinden - Performans Optimizasyonu) (Bulgu #8)
			String jti = jwtService.extractJti(jwt);
			if (jti == null) {
				handleJwtException(response, "Geçersiz oturum anahtarı: kimlik bilgisi eksik.");
				return;
			}
			if (blacklistedTokenRepository.existsByJti(jti)) {
				handleJwtException(response, "Bu oturum sonlandırılmış. Lütfen tekrar giriş yapın.");
				return;
			}

			userEmail = jwtService.extractUsername(jwt);

			if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {
				UserDetails userDetails = this.userDetailsService.loadUserByUsername(userEmail);
				if (jwtService.isTokenValid(jwt, userDetails.getUsername())) {
					UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(userDetails,
							null, userDetails.getAuthorities());
					authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
					SecurityContextHolder.getContext().setAuthentication(authToken);
				}
			}
			filterChain.doFilter(request, response);
		}
		catch (ExpiredJwtException _) {
			handleJwtException(response, "Oturum süreniz doldu. Lütfen tekrar giriş yapın.");
		}
		catch (JwtException _) {
			handleJwtException(response, "Geçersiz oturum anahtarı.");
		}
	}

	private void handleJwtException(HttpServletResponse response, String message) throws IOException {
		response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
		response.setContentType(MediaType.APPLICATION_JSON_VALUE);
		response.setCharacterEncoding("UTF-8");
		ApiResponse<Void> apiResponse = ApiResponse.error(message, clock.instant());
		response.getWriter().write(this.objectMapper.writeValueAsString(apiResponse));
	}

}
