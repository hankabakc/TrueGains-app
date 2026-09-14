package com.gym.v2.auth.service;

import com.gym.v2.auth.RegisterRequestFixture;
import com.gym.v2.auth.dto.RegisterRequest;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.entity.UserRole;
import java.math.BigDecimal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AuthMapperTest {

	private AuthMapper authMapper;

	@BeforeEach
	void setUp() {
		authMapper = new AuthMapperImpl();
	}

	@Test
	void toClientEntity_nullShowFields_defaultsToTrue() {
		RegisterRequest request = RegisterRequestFixture.valid("client@test.com", UserRole.CLIENT, "+905555555555");
		AppUser user = AppUser.builder().email("client@test.com").role(UserRole.CLIENT).build();

		ClientEntity clientEntity = authMapper.toClientEntity(user, "Ahmet Yilmaz", request);

		assertThat(clientEntity.getShowAge()).isTrue();
		assertThat(clientEntity.getShowHeight()).isTrue();
		assertThat(clientEntity.getShowWeight()).isTrue();
	}

	@Test
	void toClientEntity_explicitFalseShowFields_preservesFalse() {
		RegisterRequest base = RegisterRequestFixture.valid("client@test.com", UserRole.CLIENT, "+905555555555");
		RegisterRequest request = new RegisterRequest(base.email(), base.password(), base.role(), base.phoneNumber(),
				base.firstName(), base.lastName(), base.bio(), base.province(), base.district(), base.experienceLevel(),
				base.dateOfBirth(), base.gender(), base.heightCm(), base.weightKg(), base.goal(), base.activityLevel(),
				base.profilePhotoUrl(), false, false, false, base.specialization(), base.instagramUrl(),
				base.websiteUrl());

		AppUser user = AppUser.builder().email("client@test.com").role(UserRole.CLIENT).build();

		ClientEntity clientEntity = authMapper.toClientEntity(user, "Ahmet Yilmaz", request);

		assertThat(clientEntity.getShowAge()).isFalse();
		assertThat(clientEntity.getShowHeight()).isFalse();
		assertThat(clientEntity.getShowWeight()).isFalse();
	}

	/**
	 * Karakterizasyon testi: Üretim kodunun mevcut davranışını (boy/kilo kopyalanması)
	 * kayda geçirir.
	 */
	@Test
	void toCoachEntity_requestWithBodyMetrics_copiesHeightAndWeightToCoachEntity() {
		RegisterRequest request = RegisterRequestFixture.valid("coach@test.com", UserRole.COACH, "+905555555555");
		AppUser user = AppUser.builder().email("coach@test.com").role(UserRole.COACH).build();

		CoachEntity coachEntity = authMapper.toCoachEntity(user, "Ahmet Yilmaz", request);

		assertThat(coachEntity.getHeightCm()).isEqualTo(180);
		assertThat(coachEntity.getWeightKg()).isEqualByComparingTo(new BigDecimal("80.00"));
	}

}
