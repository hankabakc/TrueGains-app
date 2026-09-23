package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WeeklyProgressRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code WeeklyProgressService} sahiplik ve haftalık ilerleme testleri.
 * <p>
 * K1-07: Bir kullanıcının başka bir sporcunun program kimliğini vererek o programa
 * haftalık ilerleme kaydı yazması engellenmelidir (IDOR).
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class WeeklyProgressServiceTest {

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

	private final Clock fixedClock = Clock.fixed(Instant.parse("2026-09-23T10:00:00Z"), ZoneId.of("Europe/Istanbul"));

	private WeeklyProgressService service;

	@BeforeEach
	void setUp() {
		service = new WeeklyProgressService(blockRepository, workoutSessionRepository, logRepository, clientRepository,
				userRepository, weeklyProgressRepository, fixedClock);
	}

	@Test
	void upsertWeeklyProgress_programBelongsToAnotherClient_throwsNotFoundAndWritesNothing() {
		Long foreignBlockId = 999L;
		Long currentUserId = 1L;
		// Başkasına ait program için findByIdAndClientId boş döner
		when(blockRepository.findByIdAndClientId(foreignBlockId, currentUserId)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.upsertWeeklyProgress(currentUserId, foreignBlockId, LocalDate.of(2026, 9, 21)))
			.isInstanceOf(NotFoundException.class)
			.hasMessageContaining("Antrenman programı bulunamadı veya yetkiniz yok");

		verify(weeklyProgressRepository, never()).save(any());
	}

	@Test
	void upsertWeeklyProgress_ownProgram_findsAndUpdatesProgress() {
		Long ownBlockId = 100L;
		Long currentUserId = 1L;

		TrainingBlock block = new TrainingBlock();
		ReflectionTestUtils.setField(block, "id", ownBlockId);
		WorkoutDay day = new WorkoutDay();
		day.setExercises(List.of(new WorkoutExercise()));
		block.setWorkoutDays(List.of(day));

		when(blockRepository.findByIdAndClientId(ownBlockId, currentUserId)).thenReturn(Optional.of(block));
		when(workoutSessionRepository.findByUserIdAndTrainingBlockIdAndCreatedAtBetween(eq(currentUserId),
				eq(ownBlockId), any(), any()))
			.thenReturn(List.of());
		when(weeklyProgressRepository.findByUserIdAndTrainingBlockIdAndWeekStartDate(eq(currentUserId), eq(ownBlockId),
				any()))
			.thenReturn(Optional.empty());

		service.upsertWeeklyProgress(currentUserId, ownBlockId, LocalDate.of(2026, 9, 21));

		verify(weeklyProgressRepository).save(any());
	}

}
