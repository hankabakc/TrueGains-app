package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WeeklyProgressRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * {@code WeeklyProgressService} rol yetkileri ve koç-öğrenci sahiplik sınırları (KR18).
 */
@ExtendWith(MockitoExtension.class)
class WeeklyProgressAccessTest {

	@Mock
	private TrainingBlockRepository blockRepository;

	@Mock
	private WorkoutSessionRepository workoutSessionRepository;

	@Mock
	private WorkoutLogRepository logRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private WeeklyProgressRepository weeklyProgressRepository;

	private WeeklyProgressService service;

	private MockedStatic<SecurityUtils> securityUtils;

	private AppUser owner;

	private AppUser coach;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setCoachId(coachId);
		return entity;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new WeeklyProgressService(blockRepository, workoutSessionRepository, logRepository, clientRepository,
				userRepository, weeklyProgressRepository, fixedClock);

		owner = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		coach = userWithId(2L, "koc@test.com", UserRole.COACH);

		securityUtils = Mockito.mockStatic(SecurityUtils.class);
	}

	@AfterEach
	void tearDown() {
		securityUtils.close();
	}

	private void currentUserIs(AppUser user) {
		securityUtils.when(SecurityUtils::getCurrentUserEmail).thenReturn(user.getEmail());
		when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
	}

	@Test
	void clientOnly_byCoach_isForbidden() {
		currentUserIs(coach);

		assertThatThrownBy(() -> service.getWeeklyHistoryForCurrentUser()).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Bu bilgiye sadece sporcular erişebilir.");

		assertThatThrownBy(() -> service.getWeeklyProgressForCurrentUser()).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Bu bilgiye sadece sporcular erişebilir.");

		verifyNoInteractions(blockRepository, workoutSessionRepository, logRepository, clientRepository,
				weeklyProgressRepository);
	}

	@Test
	void coachOnly_byClient_isForbidden() {
		currentUserIs(owner);

		assertThatThrownBy(() -> service.getWeeklyHistoryForCoach(1L)).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Bu bilgiye sadece antrenörler erişebilir.");

		assertThatThrownBy(() -> service.getWeeklyProgressForCoach(1L)).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Bu bilgiye sadece antrenörler erişebilir.");

		assertThatThrownBy(() -> service.getExerciseProgressForCoach(1L, 5L)).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Bu bilgiye sadece antrenörler erişebilir.");

		verifyNoInteractions(clientRepository);
	}

	@Test
	void studentOfAnotherCoach_isNotFound() {
		currentUserIs(coach);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(99L)));

		assertThatThrownBy(() -> service.getWeeklyHistoryForCoach(1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Sporcu bulunamadı.");

		assertThatThrownBy(() -> service.getWeeklyProgressForCoach(1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Sporcu bulunamadı.");

		assertThatThrownBy(() -> service.getExerciseProgressForCoach(1L, 5L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Sporcu bulunamadı.");

		verifyNoInteractions(workoutSessionRepository, logRepository);
	}

}
