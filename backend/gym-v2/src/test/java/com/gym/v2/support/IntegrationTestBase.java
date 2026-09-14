package com.gym.v2.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.security.service.JwtService;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@ActiveProfiles("test")
@Transactional
public abstract class IntegrationTestBase {

	protected MockMvc mockMvc;

	@Autowired
	protected WebApplicationContext context;

	@Autowired
	protected ObjectMapper objectMapper;

	@Autowired
	protected AppUserRepository userRepository;

	@Autowired
	protected CoachRepository coachRepository;

	@Autowired
	protected ClientRepository clientRepository;

	@Autowired
	protected JwtService jwtService;

	@Autowired
	protected PasswordEncoder passwordEncoder;

	@BeforeEach
	void setUpMockMvc() {
		mockMvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
	}

	protected AppUser createUser(String email, UserRole role) {
		AppUser user = AppUser.builder()
			.email(email)
			.password(passwordEncoder.encode("Password123!"))
			.role(role)
			.registeredAt(Instant.parse("2026-01-01T00:00:00Z"))
			.phoneNumber("+905550000000")
			.isPhoneVerified(true)
			.build();
		return userRepository.saveAndFlush(user);
	}

	protected String bearerTokenFor(AppUser user) {
		return "Bearer " + jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
	}

}
