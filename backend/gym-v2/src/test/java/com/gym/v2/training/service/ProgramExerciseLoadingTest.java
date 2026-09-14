package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.service.NotificationService;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.dto.WorkoutDayDTO;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Program kaydederken egzersizlerin nasıl yüklendiği.
 * <p>
 * Bu bir yazma yolu: kayıt sırasında satır sayısı kadar INSERT üretilmesi normaldir, bu
 * yüzden toplam SQL saymak yanıltıcı olur. Ölçülen şey <b>okuma deseni</b>: programdaki
 * egzersizler tek tek mi yoksa tek sorguda mı çekiliyor. 7 günlük bir programda 40
 * egzersiz varsa aradaki fark 40 sorguya karşı 1 sorgudur.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class ProgramExerciseLoadingTest {

	@Mock
	private TrainingBlockRepository blockRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private ExerciseRepository exerciseRepository;

	@Mock
	private TrainingMapper trainingMapper;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	@Mock
	private NotificationService notificationService;

	private TrainingBlockService service;

	private MockedStatic<SecurityUtils> securityUtils;

	private AppUser client;

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new TrainingBlockService(blockRepository, clientRepository, userRepository, exerciseRepository,
				trainingMapper, messagingTemplate, notificationService,
				new com.gym.v2.core.service.TransactionalEvents(), fixedClock);

		client = AppUser.builder().email("sporcu@test.com").role(UserRole.CLIENT).build();
		ReflectionTestUtils.setField(client, "id", 1L);

		securityUtils = Mockito.mockStatic(SecurityUtils.class);
		securityUtils.when(SecurityUtils::getCurrentUserEmail).thenReturn(client.getEmail());
		when(userRepository.findByEmail(client.getEmail())).thenReturn(Optional.of(client));
	}

	@AfterEach
	void tearDown() {
		securityUtils.close();
	}

	private Exercise exercise(Long id, String name) {
		Exercise exercise = new Exercise();
		ReflectionTestUtils.setField(exercise, "id", id);
		exercise.setName(name);
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		return exercise;
	}

	private WorkoutExerciseDTO exerciseDto(Long exerciseId, int order) {
		return new WorkoutExerciseDTO(null, exerciseId, null, null, 3, "10", BigDecimal.TEN, 60, null, order, null,
				false, null);
	}

	/** İki gün, her günde iki egzersiz: dört başvuru, üç ayrı egzersiz. */
	private TrainingBlockDTO twoDayRequest() {
		WorkoutDayDTO firstDay = new WorkoutDayDTO(null, "Gun 1", 1, true,
				List.of(exerciseDto(10L, 0), exerciseDto(11L, 1)));
		WorkoutDayDTO secondDay = new WorkoutDayDTO(null, "Gun 2", 2, true,
				List.of(exerciseDto(12L, 0), exerciseDto(10L, 1)));
		return new TrainingBlockDTO(null, "Program", "Aciklama", null, null, null, null, LocalDate.of(2026, 1, 1), null,
				null, 4, List.of(firstDay, secondDay), null, null, null);
	}

	@Test
	void createPersonalProgram_loadsEveryExerciseInOneQuery() {
		when(exerciseRepository.findAllById(any()))
			.thenReturn(List.of(exercise(10L, "Bench"), exercise(11L, "Squat"), exercise(12L, "Deadlift")));

		service.createPersonalProgram(twoDayRequest());

		// Egzersiz başına sorgu atılmamalı: program büyüdükçe kaydetme pahalılaşır.
		verify(exerciseRepository, never()).findById(any());
		verify(exerciseRepository).findAllById(any());
	}

	@Test
	void createPersonalProgram_requestsEachReferencedExerciseOnlyOnce() {
		when(exerciseRepository.findAllById(any()))
			.thenReturn(List.of(exercise(10L, "Bench"), exercise(11L, "Squat"), exercise(12L, "Deadlift")));

		service.createPersonalProgram(twoDayRequest());

		ArgumentCaptor<Iterable<Long>> captor = ArgumentCaptor.captor();
		verify(exerciseRepository).findAllById(captor.capture());
		// Aynı egzersiz iki günde geçse de bir kez istenir.
		assertThat(captor.getValue()).containsExactlyInAnyOrder(10L, 11L, 12L);
	}

	@Test
	void createPersonalProgram_buildsEveryDayAndExercise() {
		when(exerciseRepository.findAllById(any()))
			.thenReturn(List.of(exercise(10L, "Bench"), exercise(11L, "Squat"), exercise(12L, "Deadlift")));

		service.createPersonalProgram(twoDayRequest());

		ArgumentCaptor<TrainingBlock> captor = ArgumentCaptor.forClass(TrainingBlock.class);
		verify(blockRepository).saveAndFlush(captor.capture());

		// Sorgu sayısını düşürmek programı eksiltmemeli.
		TrainingBlock saved = captor.getValue();
		assertThat(saved.getWorkoutDays()).hasSize(2);
		assertThat(saved.getWorkoutDays().getFirst().getExercises()).hasSize(2);
		assertThat(saved.getWorkoutDays().getFirst().getExercises().getFirst().getExercise().getName())
			.isEqualTo("Bench");
	}

	@Test
	void createPersonalProgram_unknownExercise_isRejectedAndSavesNothing() {
		// Sunucu, istenen egzersizlerden birini bulamadı.
		when(exerciseRepository.findAllById(any())).thenReturn(List.of(exercise(10L, "Bench"), exercise(11L, "Squat")));

		assertThatThrownBy(() -> service.createPersonalProgram(twoDayRequest())).isInstanceOf(NotFoundException.class)
			.hasMessageContaining("12");

		verify(blockRepository, never()).saveAndFlush(any());
	}

}
