package com.gym.v2.auth.controller;

import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.service.AuthenticationService;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.GlobalExceptionHandler;
import com.gym.v2.core.service.LogService;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.MessageSource;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AuthenticationControllerTest {

	private MockMvc mockMvc;

	@Mock
	private AuthenticationService authenticationService;

	@Mock
	private MessageSource messageSource;

	@Mock
	private LogService logService;

	private Clock fixedClock;

	@BeforeEach
	void setUp() {
		fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);

		LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
		validator.afterPropertiesSet();

		GlobalExceptionHandler exceptionHandler = new GlobalExceptionHandler(messageSource, fixedClock, logService);
		AuthController controller = new AuthController(authenticationService, messageSource, fixedClock);

		mockMvc = MockMvcBuilders.standaloneSetup(controller)
			.setValidator(validator)
			.setControllerAdvice(exceptionHandler)
			.build();
	}

	private String validJson(String email, String password) {
		return """
				{
				  "email": "%s",
				  "password": "%s",
				  "role": "CLIENT",
				  "phoneNumber": "+905555555555",
				  "firstName": "Ahmet",
				  "lastName": "Yilmaz",
				  "bio": "Test bio",
				  "province": "Istanbul",
				  "district": "Kadikoy",
				  "experienceLevel": "INTERMEDIATE",
				  "dateOfBirth": "2000-01-01",
				  "gender": "MALE",
				  "heightCm": 180,
				  "weightKg": 80.00,
				  "goal": "KILO_VER",
				  "activityLevel": "MODERATELY_ACTIVE",
				  "profilePhotoUrl": "https://example.com/photo.jpg",
				  "specialization": "FITNESS",
				  "instagramUrl": "https://www.instagram.com/testcoach",
				  "websiteUrl": "https://example.com"
				}
				""".formatted(email, password);
	}

	@Test
	void register_invalidEmailFormat_returnsBadRequest() throws Exception {
		String body = validJson("invalid-email", "Password123!");

		mockMvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
			.andExpect(status().isBadRequest())
			.andExpect(jsonPath("$.success").value(false));
	}

	@Test
	void register_shortPassword_returnsBadRequest() throws Exception {
		String body = validJson("valid@example.com", "short");

		mockMvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
			.andExpect(status().isBadRequest())
			.andExpect(jsonPath("$.success").value(false));
	}

	@Test
	void register_validRequest_callsServiceAndReturnsCreated() throws Exception {
		String body = validJson("valid@example.com", "Password123!");

		mockMvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
			.andExpect(status().isCreated());

		verify(authenticationService).register(any(RegisterRequest.class));
	}

	@Test
	void register_serviceThrowsBadRequestException_returnsBadRequestWithMessage() throws Exception {
		String body = validJson("valid@example.com", "Password123!");
		doThrow(new BadRequestException("Bu e-posta kullanımda")).when(authenticationService)
			.register(any(RegisterRequest.class));

		mockMvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON).content(body))
			.andExpect(status().isBadRequest())
			.andExpect(jsonPath("$.message").value("Bu e-posta kullanımda"));
	}

}
