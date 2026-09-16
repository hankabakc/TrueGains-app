package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.dto.WorkoutLogDTO;
import com.gym.v2.training.dto.WorkoutLogRequestDTO;
import com.gym.v2.training.dto.WorkoutSessionRequestDTO;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.WorkoutExerciseRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
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
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code WorkoutSessionService} sahiplik (IDOR) sınırları.
 * <p>
 * Set logu ve idman kaydı silme işlemlerinde kimlik URL'den gelir. Koruma olmazsa bir
 * sporcu başkasının programına set yazabilir veya başkasının idman geçmişini silebilir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class WorkoutSessionOwnershipTest {

	@Mock
	private WorkoutSessionRepository workoutSessionRepository;

	@Mock
	private WorkoutLogRepository logRepository;

	@Mock
	private WorkoutExerciseRepository workoutExerciseRepository;

	@Mock
	private ExerciseRepository exerciseRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private WeeklyProgressService weeklyProgressService;

	@Mock
	private TrainingMapper trainingMapper;

	private WorkoutSessionService service;

	private MockedStatic<SecurityUtils> securityUtils;

	private AppUser owner;

	private AppUser otherClient;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new WorkoutSessionService(workoutSessionRepository, logRepository, workoutExerciseRepository,
				exerciseRepository, userRepository, clientRepository, weeklyProgressService, trainingMapper,
				fixedClock);

		owner = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		otherClient = userWithId(99L, "baska.sporcu@test.com", UserRole.CLIENT);

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

	private WorkoutLogDTO logRequest() {
		return new WorkoutLogDTO(null, null, null, 1, BigDecimal.valueOf(60), 10, 8, null, null);
	}

	/** Sahibi sporcu 1 olan idman kaydı. */
	private WorkoutSession session() {
		WorkoutSession session = new WorkoutSession(owner, "Gun 1", 3600);
		session.setId(50L);
		return session;
	}

	// ---------------------------------------------------------------------------
	// logSet — egzersiz sorgusu her zaman aktif sporcuya daraltılmalı
	// ---------------------------------------------------------------------------

	@Test
	void logSet_exerciseOfAnotherClientsProgram_isRejectedAndWritesNothing() {
		currentUserIs(otherClient);
		// Egzersiz 1000 sporcu 1'in programına ait; sporcu 99 için sorgu boş döner.
		when(workoutExerciseRepository.findByIdAndWorkoutDay_TrainingBlock_Client_Id(1000L, 99L))
			.thenReturn(Optional.empty());
		// Kayıt veritabanında vardır; sahiplik filtresi kalkarsa erişilebilir hale gelir.
		lenient().when(workoutExerciseRepository.findById(1000L)).thenReturn(Optional.of(new WorkoutExercise()));

		assertThatThrownBy(() -> service.logSet(1000L, logRequest())).isInstanceOf(NotFoundException.class);

		verify(logRepository, never()).save(any());
	}

	@Test
	void logSet_ownExercise_savesAndQueriesScopedToCurrentUser() {
		currentUserIs(owner);
		when(workoutExerciseRepository.findByIdAndWorkoutDay_TrainingBlock_Client_Id(1000L, 1L))
			.thenReturn(Optional.of(new WorkoutExercise()));

		service.logSet(1000L, logRequest());

		// Sorgu aktif sporcunun kimliğiyle daraltılmış olmalı.
		verify(workoutExerciseRepository).findByIdAndWorkoutDay_TrainingBlock_Client_Id(1000L, 1L);
		verify(logRepository).save(any());
	}

	// ---------------------------------------------------------------------------
	// logWorkoutSession — toplu log; hem sahiplik hem "hiçbir set kaybolmasın"
	// ---------------------------------------------------------------------------

	private WorkoutExercise exerciseWithId(Long id) {
		WorkoutExercise exercise = new WorkoutExercise();
		ReflectionTestUtils.setField(exercise, "id", id);
		return exercise;
	}

	private WorkoutLogRequestDTO logFor(Long workoutExerciseId, int setIndex) {
		return new WorkoutLogRequestDTO(workoutExerciseId, setIndex, BigDecimal.valueOf(60), 10, 8, null, null);
	}

	@Test
	void logWorkoutSession_oneExerciseBelongsToAnotherClient_isRejectedAndSavesNothing() {
		currentUserIs(otherClient);
		// Sorgu aktif sporcuya daraltıldığı için yabancı egzersiz (2000) geri dönmez.
		when(workoutExerciseRepository.findAllByIdInAndWorkoutDay_TrainingBlock_Client_Id(any(), eq(99L)))
			.thenReturn(List.of(exerciseWithId(1000L)));
		// Her iki kayıt da veritabanında mevcut; sorgu daraltması kalkarsa erişilebilir
		// hâle gelirler.
		lenient().when(workoutExerciseRepository.findAllById(any()))
			.thenReturn(List.of(exerciseWithId(1000L), exerciseWithId(2000L)));

		WorkoutSessionRequestDTO request = new WorkoutSessionRequestDTO("Gun 1", 3600,
				List.of(logFor(1000L, 1), logFor(2000L, 2)), null, null, null);

		assertThatThrownBy(() -> service.logWorkoutSession(request)).isInstanceOf(NotFoundException.class);

		// Tek yabancı set tüm idmanı geçersiz kılmalı; yarım kayıt oluşmamalı.
		verify(workoutSessionRepository, never()).save(any());
		verify(weeklyProgressService, never()).upsertWeeklyProgress(any(), any(), any());
	}

	@Test
	void logWorkoutSession_allExercisesOwned_savesEverySetWithTheSession() {
		currentUserIs(owner);
		when(workoutExerciseRepository.findAllByIdInAndWorkoutDay_TrainingBlock_Client_Id(any(), eq(1L)))
			.thenReturn(List.of(exerciseWithId(1000L), exerciseWithId(1001L)));
		lenient().when(workoutExerciseRepository.findAllById(any()))
			.thenReturn(List.of(exerciseWithId(1000L), exerciseWithId(1001L)));
		when(workoutSessionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		WorkoutSessionRequestDTO request = new WorkoutSessionRequestDTO("Gun 1", 3600,
				List.of(logFor(1000L, 1), logFor(1000L, 2), logFor(1001L, 1)), null, null, null);

		service.logWorkoutSession(request);

		ArgumentCaptor<WorkoutSession> captor = ArgumentCaptor.forClass(WorkoutSession.class);
		verify(workoutSessionRepository).save(captor.capture());
		// Gönderilen üç setin üçü de kaydedilmeli.
		assertThat(captor.getValue().getLogs()).hasSize(3);
	}

	@Test
	void logWorkoutSession_withTrainingBlock_updatesWeeklyProgressForTheCurrentUser() {
		currentUserIs(owner);
		when(workoutSessionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		WorkoutSessionRequestDTO request = new WorkoutSessionRequestDTO("Gun 1", 3600, List.of(), 5L, null, null);

		service.logWorkoutSession(request);

		// Sabit saat 2026-01-01 (Perşembe); haftanın başlangıcı 2025-12-29 Pazartesi.
		verify(weeklyProgressService).upsertWeeklyProgress(1L, 5L, LocalDate.of(2025, 12, 29));
	}

	@Test
	void logWorkoutSession_withoutTrainingBlock_doesNotTouchWeeklyProgress() {
		currentUserIs(owner);
		when(workoutSessionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		service.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 3600, List.of(), null, null, null));

		verify(weeklyProgressService, never()).upsertWeeklyProgress(any(), any(), any());
	}

	// ---------------------------------------------------------------------------
	// deleteWorkoutSession — yalnızca kaydın sahibi
	// ---------------------------------------------------------------------------

	@Test
	void deleteWorkoutSession_notTheOwner_isRejectedAndDeletesNothing() {
		currentUserIs(otherClient);
		when(workoutSessionRepository.findById(50L)).thenReturn(Optional.of(session()));

		assertThatThrownBy(() -> service.deleteWorkoutSession(50L)).isInstanceOf(BadRequestException.class);

		verify(workoutSessionRepository, never()).delete(any());
	}

	@Test
	void deleteWorkoutSession_owner_deletes() {
		WorkoutSession session = session();
		currentUserIs(owner);
		when(workoutSessionRepository.findById(50L)).thenReturn(Optional.of(session));

		service.deleteWorkoutSession(50L);

		verify(workoutSessionRepository).delete(session);
	}

	@Test
	void deleteWorkoutSession_unknownSession_throwsNotFound() {
		currentUserIs(owner);
		when(workoutSessionRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.deleteWorkoutSession(404L)).isInstanceOf(NotFoundException.class);

		verify(workoutSessionRepository, never()).delete(any());
	}

	@Test
	void logWorkoutSession_sameLocalIdAlreadySaved_returnsExistingAndSavesNothing() {
		currentUserIs(owner);
		WorkoutSession existing = session();
		when(workoutSessionRepository.findByUserIdAndLocalIdWithLogs(1L, "yerel-1")).thenReturn(Optional.of(existing));

		service.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 3600, List.of(), 5L, null, "yerel-1"));

		verify(trainingMapper).toWorkoutSessionDTO(existing);
		verify(workoutSessionRepository, never()).save(any());
		verify(weeklyProgressService, never()).upsertWeeklyProgress(any(), any(), any());
	}

	@Test
	void logWorkoutSession_newLocalId_isStoredOnTheSession() {
		currentUserIs(owner);
		when(workoutSessionRepository.findByUserIdAndLocalIdWithLogs(1L, "yerel-2")).thenReturn(Optional.empty());
		when(workoutSessionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		service.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 3600, List.of(), null, null, "yerel-2"));

		ArgumentCaptor<WorkoutSession> captor = ArgumentCaptor.forClass(WorkoutSession.class);
		verify(workoutSessionRepository).save(captor.capture());
		assertThat(captor.getValue().getLocalId()).isEqualTo("yerel-2");
	}

	@Test
	void logWorkoutSession_withoutLocalId_doesNotLookUpExisting() {
		currentUserIs(owner);
		when(workoutSessionRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		service.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 3600, List.of(), null, null, null));

		verify(workoutSessionRepository, never()).findByUserIdAndLocalIdWithLogs(any(), any());
		verify(workoutSessionRepository).save(any());
	}

}
