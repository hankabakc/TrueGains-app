package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.repository.WaterIntakeRepository;
import com.gym.v2.nutrition.repository.WaterTargetRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code CoachWaterTrackingService} koç-sporcu sahiplik kontrolü.
 * <p>
 * Sporcu kimliği URL'den gelir. Koruma olmazsa herhangi bir koç, sistemdeki her sporcunun
 * su tüketim verisini okuyabilir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class CoachWaterTrackingServiceTest {

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private WaterIntakeRepository intakeRepository;

	@Mock
	private WaterTargetRepository targetRepository;

	@Mock
	private EncryptionConverter encryptionConverter;

	@Mock
	private UserContextService userContextService;

	private CoachWaterTrackingService service;

	private AppUser coach;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new CoachWaterTrackingService(clientRepository, intakeRepository, targetRepository,
				encryptionConverter, userContextService, fixedClock);

		coach = userWithId(2L, "koc@test.com");
		lenient().when(userContextService.getCurrentUser()).thenReturn(coach);
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setCoachId(coachId);
		return entity;
	}

	@Test
	void getStudentWaterIntake_clientAssignedToAnotherCoach_throwsAndReadsNoData() {
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(7L)));

		assertThatThrownBy(() -> service.getStudentWaterIntake(50L)).isInstanceOf(BadRequestException.class);

		verify(intakeRepository, never()).getTotalIntakeByDate(any(), any());
	}

	@Test
	void getStudentWaterIntake_clientWithoutAnyCoach_isRejected() {
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(null)));

		// Koçu olmayan sporcunun verisi hiçbir koça açık olmamalı.
		assertThatThrownBy(() -> service.getStudentWaterIntake(50L)).isInstanceOf(BadRequestException.class);
	}

	@Test
	void getStudentWaterIntake_unknownClient_throwsNotFound() {
		when(clientRepository.findByUserId(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getStudentWaterIntake(404L)).isInstanceOf(NotFoundException.class);
	}

}
