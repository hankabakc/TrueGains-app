package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.dto.WorkoutDayDTO;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutExerciseRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.service.*;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;
import com.gym.v2.core.service.NotificationService;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.*;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

public class TrainingServiceTest {

	@Mock
	private TrainingBlockRepository blockRepository;

	@Mock
	private ExerciseRepository exerciseRepository;

	@Mock
	private WorkoutLogRepository logRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private WorkoutExerciseRepository workoutExerciseRepository;

	@Mock
	private WorkoutSessionRepository workoutSessionRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private TrainingMapper trainingMapper;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	@Mock
	private NotificationService notificationService;

	@Spy
	private Clock clock = Clock.systemDefaultZone();

	private TrainingService trainingService;

	private MockedStatic<SecurityUtils> mockedSecurityUtils;

	@BeforeEach
	void setUp() {
		MockitoAnnotations.openMocks(this);

		// TrainingBlockService oluşturulur (Gerçek bağımlılık mocks ile)
		TrainingBlockService trainingBlockService = new TrainingBlockService(blockRepository, clientRepository,
				userRepository, exerciseRepository, trainingMapper, messagingTemplate, notificationService,
				new com.gym.v2.core.service.TransactionalEvents(), clock);

		// Diğer alt servisler mocklanır
		WorkoutSessionService workoutSessionService = mock(WorkoutSessionService.class);
		WeeklyProgressService weeklyProgressService = mock(WeeklyProgressService.class);
		ExerciseService exerciseService = mock(ExerciseService.class);

		// TrainingService Facade olarak başlatılır
		trainingService = new TrainingService(trainingBlockService, workoutSessionService, weeklyProgressService,
				exerciseService);

		mockedSecurityUtils = mockStatic(SecurityUtils.class);
	}

	@AfterEach
	void tearDown() {
		mockedSecurityUtils.close();
	}

	@Test
	void testUpdatePersonalProgram_AddExercise_ShouldPersistCorrectCount() {
		// 1. GIVEN: Mevcut bir program (1 gün, 1 egzersiz)
		Long programId = 1L;
		Long clientId = 10L;

		AppUser client = AppUser.builder().email("test@test.com").role(UserRole.CLIENT).build();
		ReflectionTestUtils.setField(client, "id", clientId);

		TrainingBlock existingBlock = new TrainingBlock("Program", "Desc", null, client, LocalDate.now(),
				LocalDate.now().plusMonths(1));
		ReflectionTestUtils.setField(existingBlock, "id", programId);
		existingBlock.setIsActive(true);
		existingBlock.setVersion(1L);

		WorkoutDay day1 = new WorkoutDay(existingBlock, "Day 1", 1);
		ReflectionTestUtils.setField(day1, "id", 100L);
		day1.setExercises(new ArrayList<>());

		Exercise ex1 = new Exercise();
		ReflectionTestUtils.setField(ex1, "id", 500L);
		ex1.setName("Ex 1");

		WorkoutExercise we1 = new WorkoutExercise(day1, ex1, 3, "10", BigDecimal.ZERO, 60, null, 0, false);
		ReflectionTestUtils.setField(we1, "id", 1000L);
		day1.addExercise(we1);

		existingBlock.setWorkoutDays(new ArrayList<>(List.of(day1)));

		// 2. Mocking
		mockedSecurityUtils.when(SecurityUtils::getCurrentUserEmail).thenReturn("test@test.com");
		when(userRepository.findByEmail("test@test.com")).thenReturn(Optional.of(client));
		when(blockRepository.findById(programId)).thenReturn(Optional.of(existingBlock));
		Exercise ex2 = new Exercise();
		ReflectionTestUtils.setField(ex2, "id", 501L);
		ex2.setName("Ex 2");
		// Programdaki egzersizler tek sorguda çekiliyor (N+1 önlemi).
		when(exerciseRepository.findAllById(any())).thenReturn(List.of(ex1, ex2));

		// Mock saveAndFlush to return the block itself
		when(blockRepository.saveAndFlush(any())).thenAnswer(i -> i.getArguments()[0]);

		// 3. WHEN: Yeni bir egzersiz eklenmiş DTO geliyor (we1 duruyor, we2 yeni eklendi)
		WorkoutExerciseDTO weDto1 = new WorkoutExerciseDTO(1000L, 500L, "Ex 1", null, 3, "10", BigDecimal.ZERO, 60,
				null, 0, null, false, null);
		WorkoutExerciseDTO weDto2 = new WorkoutExerciseDTO(0L, 501L, "Ex 2", null, 3, "10", BigDecimal.ZERO, 60, null,
				1, null, false, null);

		WorkoutDayDTO dayDto = new WorkoutDayDTO(100L, "Day 1", 1, true, List.of(weDto1, weDto2));
		TrainingBlockDTO request = new TrainingBlockDTO(programId, "Program", "Desc", null, null, clientId, null,
				LocalDate.now(), LocalDate.now().plusMonths(1), true, 4, List.of(dayDto), true, false, false);

		trainingService.updatePersonalProgram(programId, request);

		// 4. THEN: Veritabanına kaydedilen blokta 2 egzersiz olmalı
		ArgumentCaptor<TrainingBlock> captor = ArgumentCaptor.forClass(TrainingBlock.class);
		verify(blockRepository, atLeastOnce()).saveAndFlush(captor.capture());

		TrainingBlock savedBlock = captor.getValue();
		assertEquals(1, savedBlock.getWorkoutDays().size());
		assertEquals(2, savedBlock.getWorkoutDays().get(0).getExercises().size(), "Egzersiz sayısı 2 olmalı!");
	}

}
