package com.gym.v2.core.security.config;

import com.gym.v2.core.security.interceptor.JwtChannelInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.util.List;

/**
 * WebSocket Konfigürasyonu. Gerçek zamanlı mesajlaşma için STOMP protokolünü aktif eder.
 * Güvenlik iyileştirmeleri (Origin kısıtlama ve JWT doğrulama) içerir.
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

	@Value("${app.security.cors.allowed-origins:http://localhost:3000,http://localhost:8080,capacitor://localhost}")
	private List<String> allowedOrigins;

	private final JwtChannelInterceptor jwtChannelInterceptor;

	public WebSocketConfig(JwtChannelInterceptor jwtChannelInterceptor) {
		this.jwtChannelInterceptor = jwtChannelInterceptor;
	}

	@Override
	public void configureMessageBroker(MessageBrokerRegistry config) {
		// Sunucudan istemciye giden mesajlar için önek
		config.enableSimpleBroker("/topic", "/queue");
		// İstemciden sunucuya gelen mesajlar için önek
		config.setApplicationDestinationPrefixes("/app");
		// Kullanıcıya özel (Private) mesajlar için önek
		config.setUserDestinationPrefix("/user");
	}

	@Override
	public void registerStompEndpoints(StompEndpointRegistry registry) {
		// Güvenlik Bulgu #4: Wildcard origin kaldırıldı, güvenli liste eklendi.
		String[] origins = allowedOrigins.toArray(String[]::new);

		registry.addEndpoint("/ws").setAllowedOriginPatterns(origins).withSockJS();

		registry.addEndpoint("/ws-raw").setAllowedOriginPatterns(origins);
	}

	@Override
	public void configureClientInboundChannel(ChannelRegistration registration) {
		// Güvenlik Bulgu #5: STOMP bağlantıları için JWT doğrulama interceptor'ı eklendi.
		registration.interceptors(jwtChannelInterceptor);
	}

}
