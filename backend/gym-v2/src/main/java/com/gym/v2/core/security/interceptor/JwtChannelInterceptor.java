package com.gym.v2.core.security.interceptor;

import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.service.CustomUserDetails;
import com.gym.v2.core.security.service.JwtService;
import com.gym.v2.core.security.service.UserDetailsServiceImpl;
import com.gym.v2.auth.repository.BlacklistedTokenRepository;
import com.gym.v2.social.repository.ConversationRepository;
import com.gym.v2.core.service.LogService;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.security.Principal;

/**
 * WebSocket bağlantıları (STOMP) için JWT doğrulama interceptor'ı. Bağlantı kurulurken
 * (CONNECT frame) Authorization başlığını kontrol eder.
 */
@Component
public class JwtChannelInterceptor implements ChannelInterceptor {

	private final JwtService jwtService;

	private final UserDetailsServiceImpl userDetailsService;

	private final ConversationRepository conversationRepository;

	private final BlacklistedTokenRepository blacklistedTokenRepository;

	private final LogService logService;

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(JwtChannelInterceptor.class);

	public JwtChannelInterceptor(JwtService jwtService, UserDetailsServiceImpl userDetailsService,
			ConversationRepository conversationRepository, BlacklistedTokenRepository blacklistedTokenRepository,
			LogService logService) {
		this.jwtService = jwtService;
		this.userDetailsService = userDetailsService;
		this.conversationRepository = conversationRepository;
		this.blacklistedTokenRepository = blacklistedTokenRepository;
		this.logService = logService;
	}

	@Override
	public Message<?> preSend(Message<?> message, MessageChannel channel) {
		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

		if (accessor == null) {
			return message;
		}

		try {
			if (StompCommand.CONNECT.equals(accessor.getCommand())) {
				String authHeader = accessor.getFirstNativeHeader(SecurityConstants.AUTH_HEADER);
				String jwt = SecurityUtils.extractToken(authHeader);

				if (jwt != null && !isBlacklisted(jwt)) {
					String userEmail = jwtService.extractUsername(jwt);
					if (userEmail != null) {
						UserDetails userDetails = userDetailsService.loadUserByUsername(userEmail);
						if (jwtService.isTokenValid(jwt, userDetails.getUsername())) {
							UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
									userDetails, null, userDetails.getAuthorities());
							accessor.setUser(authentication);
						}
					}
				}

				// Güvenlik Bulgu #5: Kimlik doğrulanmamış bağlantıları reddet
				if (accessor.getUser() == null) {
					throw new MessageDeliveryException("WebSocket bağlantısı için geçersiz veya eksik JWT.");
				}
			}
			else if (StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
				validateSubscription(accessor);
			}
		}
		catch (MessageDeliveryException e) {
			if (log.isWarnEnabled()) {
				log.warn("[WebSocket Stomp Security] Command: {}, Destination: {} -> Yetkilendirme/Bağlantı hatası: {}",
						accessor.getCommand(), accessor.getDestination(), e.getMessage());
			}
			throw e;
		}
		catch (Exception e) {
			log.error("[WebSocket Stomp Error] Command: {}, Destination: {} -> Hata: {}", accessor.getCommand(),
					accessor.getDestination(), e.getMessage(), e);
			logService.error(e);
			throw e;
		}

		return message;
	}

	/**
	 * Çıkış yapılmış (kara listeye alınmış) bir token'ın WebSocket'e bağlanmasını
	 * engeller.
	 * <p>
	 * {@code isTokenValid} yalnızca imzaya ve son kullanma tarihine bakar; çıkışı bilmez.
	 * Bu kontrol olmadan kullanıcı çıkış yaptıktan sonra elindeki access token'la sohbete
	 * bağlanıp mesajları dinlemeye devam edebiliyordu — çalınmış token senaryosunda çıkış
	 * yapmak kullanıcıyı korumuyordu. HTTP tarafında aynı kontrol
	 * {@code JwtAuthenticationFilter} içinde zaten var.
	 * </p>
	 */
	private boolean isBlacklisted(String jwt) {
		String jti = jwtService.extractJti(jwt);
		// jti yoksa token bu uygulamanın ürettiği biçimde değildir; güvenli taraf
		// reddetmektir.
		return jti == null || blacklistedTokenRepository.existsByJti(jti);
	}

	private void validateSubscription(StompHeaderAccessor accessor) {
		String destination = accessor.getDestination();
		if (destination == null) {
			return;
		}

		Principal principal = accessor.getUser();
		if (principal == null) {
			throw new MessageDeliveryException("Kimlik doğrulanmamış abonelik isteği.");
		}

		if (destination.startsWith("/topic/chat/")) {
			validateChatSubscription(destination, principal);
		}
		else if (destination.startsWith("/topic/user/") && destination.endsWith("/conversations")) {
			validateUserConversationsSubscription(destination, principal);
		}
	}

	private void validateChatSubscription(String destination, Principal principal) {
		try {
			String rawId = destination.substring("/topic/chat/".length());
			if (rawId.contains("/")) {
				rawId = rawId.substring(0, rawId.indexOf("/"));
			}
			Long conversationId = Long.parseLong(rawId);

			String userEmail = principal.getName();
			boolean hasAccess = conversationRepository.findByIdWithUsers(conversationId)
				.map(conv -> conv.getClient().getEmail().equals(userEmail)
						|| conv.getCoach().getEmail().equals(userEmail))
				.orElse(false);

			if (!hasAccess) {
				throw new MessageDeliveryException("Bu konuşmayı dinleme yetkiniz yok.");
			}
		}
		catch (NumberFormatException e) {
			throw new MessageDeliveryException("Geçersiz konuşma ID formatı.");
		}
	}

	private void validateUserConversationsSubscription(String destination, Principal principal) {
		try {
			// /topic/user/{userId}/conversations
			String userIdStr = destination.substring("/topic/user/".length(), destination.lastIndexOf("/"));
			Long targetUserId = Long.parseLong(userIdStr);

			if (principal instanceof UsernamePasswordAuthenticationToken auth) {
				if (auth.getPrincipal() instanceof CustomUserDetails userDetails) {
					if (!userDetails.getId().equals(targetUserId)) {
						throw new MessageDeliveryException(
								"Sadece kendi sohbet güncellemelerinize abone olabilirsiniz.");
					}
					return;
				}
			}
			throw new MessageDeliveryException("Kullanıcı bilgileri doğrulanamadı.");
		}
		catch (NumberFormatException | IndexOutOfBoundsException e) {
			throw new MessageDeliveryException("Geçersiz kullanıcı ID formatı.");
		}
	}

}
