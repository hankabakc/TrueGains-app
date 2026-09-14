package com.gym.v2.core.security.service;

import com.gym.v2.auth.entity.UserRole;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.Clock;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

@Service
public class JwtService {

	@Value("${app.security.jwt.secret}")
	private String secretKey;

	@Value("${app.security.jwt.expiration}")
	private long jwtExpiration;

	private SecretKey signInKey;

	private final Clock clock;

	public JwtService(Clock clock) {
		this.clock = clock;
	}

	@PostConstruct
	public void init() {
		this.signInKey = buildSignInKey();
	}

	public long getJwtExpirationSeconds() {
		return jwtExpiration / 1000;
	}

	public String extractUsername(String token) {
		return extractClaim(token, Claims::getSubject);
	}

	public Long extractUserId(String token) {
		final Claims claims = extractAllClaims(token);
		return claims.get("userId", Long.class);
	}

	public String extractJti(String token) {
		return extractClaim(token, Claims::getId);
	}

	public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
		final Claims claims = extractAllClaims(token);
		return claimsResolver.apply(claims);
	}

	public String generateToken(Long userId, String email, UserRole role) {
		Map<String, Object> claims = new HashMap<>();
		claims.put("userId", userId);
		claims.put("role", role.name());
		claims.put(Claims.ID, UUID.randomUUID().toString());
		return buildToken(claims, email, jwtExpiration);
	}

	private String buildToken(Map<String, Object> extraClaims, String subject, long expiration) {
		return Jwts.builder()
			.claims(extraClaims)
			.subject(subject)
			.issuedAt(Date.from(clock.instant()))
			.expiration(Date.from(clock.instant().plusMillis(expiration)))
			.signWith(getSignInKey(), Jwts.SIG.HS256)
			.compact();
	}

	public boolean isTokenValid(String token, String userEmail) {
		final String username = extractUsername(token);
		return (username.equals(userEmail)) && !isTokenExpired(token);
	}

	private boolean isTokenExpired(String token) {
		return extractExpiration(token).toInstant().isBefore(clock.instant());
	}

	public Date extractExpiration(String token) {
		return extractClaim(token, Claims::getExpiration);
	}

	private Claims extractAllClaims(String token) {
		return Jwts.parser().verifyWith(getSignInKey()).build().parseSignedClaims(token).getPayload();
	}

	private SecretKey getSignInKey() {
		return this.signInKey;
	}

	private SecretKey buildSignInKey() {
		byte[] keyBytes = Decoders.BASE64.decode(secretKey);
		return Keys.hmacShaKeyFor(keyBytes);
	}

}
