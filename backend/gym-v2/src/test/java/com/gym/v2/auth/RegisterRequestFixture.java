package com.gym.v2.auth;

import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.UserRole;
import java.math.BigDecimal;
import java.time.LocalDate;

public final class RegisterRequestFixture {

	private RegisterRequestFixture() {
	}

	public static RegisterRequest valid(String email, UserRole role, String phoneNumber) {
		return new RegisterRequest(email, "Password123!", role, phoneNumber, "Ahmet", "Yilmaz", "Test bio", "Istanbul",
				"Kadikoy", "INTERMEDIATE", LocalDate.of(2000, 1, 1), "MALE", 180, new BigDecimal("80.00"), "KILO_VER",
				"MODERATELY_ACTIVE", "https://example.com/photo.jpg", null, null, null, "FITNESS",
				"https://www.instagram.com/testcoach", "https://example.com");
	}

}
