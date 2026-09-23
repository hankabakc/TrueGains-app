package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * İnternetsiz oluşturulan kişisel programla antrenman (G-74, KR13). Kuyruk eklenme
 * sırasıyla gider: program oluşturma → yerel kimlikle etkinleştirme → antrenman. Gün ve
 * egzersiz cihazda negatif geçici kimlik taşır; oturum egzersize bu kimlikle bağlanır.
 */
class OfflineProgramWorkoutIT extends IntegrationTestBase {

	private static final long LOCAL_EXERCISE_ID = -501;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private WorkoutSessionRepository sessionRepository;

	@PersistenceContext
	private EntityManager entityManager;

	/**
	 * Önceki bir test sınıfının iş parçacığında bıraktığı kimlik JWT filtresini atlatır
	 * (filtre bağlamda kimlik varsa jetona bakmıyor) ve ilk istek yetkisiz kalır.
	 */
	@BeforeEach
	void clearLeakedAuthentication() {
		SecurityContextHolder.clearContext();
	}

	private Exercise savedExercise() {
		Exercise exercise = new Exercise();
		exercise.setName("Squat");
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		exercise.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return exerciseRepository.saveAndFlush(exercise);
	}

	private void createQueuedProgram(AppUser user, String localId, Exercise exercise) throws Exception {
		Map<String, Object> workoutExercise = Map.of("id", LOCAL_EXERCISE_ID, "exercise_id", exercise.getId(),
				"target_sets", 3, "target_reps", "10", "order_index", 0);
		Map<String, Object> day = Map.of("id", -11, "name", "Pazartesi", "day_order", 1, "exercises",
				List.of(workoutExercise));
		String body = objectMapper.writeValueAsString(Map.of("name", "Yerel Program", "start_date", "2026-09-23",
				"duration_weeks", 4, "workout_days", List.of(day), "local_id", localId));
		mockMvc
			.perform(post("/api/v1/training/programs/personal").header("Authorization", bearerTokenFor(user))
				.contentType(MediaType.APPLICATION_JSON)
				.content(body))
			.andExpect(status().isOk());
	}

	/** Cihazın gönderdiği biçim: program ve gün sunucu kimliği olmadan (0 / negatif). */
	private String offlineSessionJson() throws Exception {
		Map<String, Object> log = Map.of("workoutExerciseId", LOCAL_EXERCISE_ID, "setIndex", 1, "actualWeight", 80,
				"actualReps", 10);
		Map<String, Object> body = new HashMap<>(Map.of("workoutDayName", "Pazartesi", "totalSeconds", 600, "logs",
				List.of(log), "trainingBlockId", 0, "workoutDayId", -11, "localId", "yerel-oturum-1"));
		return objectMapper.writeValueAsString(body);
	}

	@Test
	void queuedProgram_activatedAndTrainedOffline_sessionLinksToCreatedProgram() throws Exception {
		AppUser client = createUser("offline_prog@test.com", UserRole.CLIENT);
		createQueuedProgram(client, "yerel-program", savedExercise());

		mockMvc
			.perform(post("/api/v1/training/activate/local/yerel-program").header("Authorization",
					bearerTokenFor(client)))
			.andExpect(status().isOk());
		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(offlineSessionJson()))
			.andExpect(status().isOk());
		entityManager.flush();
		entityManager.clear();

		TrainingBlock block = blockRepository.findByClientIdAndLocalId(client.getId(), "yerel-program").orElseThrow();
		WorkoutDay day = block.getWorkoutDays().getFirst();
		WorkoutSession session = sessionRepository.findHistoryWithLogs(client.getId()).getFirst();
		assertThat(block.getIsActive()).isTrue();
		assertThat(session.getTrainingBlockId()).isEqualTo(block.getId());
		assertThat(session.getWorkoutDayId()).isEqualTo(day.getId());
		assertThat(session.getLogs()).extracting(log -> log.getWorkoutExercise().getId())
			.containsExactly(day.getExercises().getFirst().getId());
	}

	@Test
	void sessionWithAnotherClientsLocalExerciseId_isNotFoundAndNothingStored() throws Exception {
		AppUser owner = createUser("offline_owner@test.com", UserRole.CLIENT);
		AppUser other = createUser("offline_other@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "sahibin-programi", savedExercise());

		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(offlineSessionJson()))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(sessionRepository.findHistoryWithLogs(other.getId())).isEmpty();
	}

	@Test
	void activateByLocalId_ofAnotherClientsProgram_isNotFoundAndNothingActivated() throws Exception {
		AppUser owner = createUser("activate_owner@test.com", UserRole.CLIENT);
		AppUser other = createUser("activate_other@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "baskasinin-programi", savedExercise());

		mockMvc
			.perform(post("/api/v1/training/activate/local/baskasinin-programi").header("Authorization",
					bearerTokenFor(other)))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(blockRepository.findByClientIdAndLocalId(owner.getId(), "baskasinin-programi")
			.orElseThrow()
			.getIsActive()).isFalse();
	}

	/**
	 * Düzenleyici tarihi bugün olarak gönderir; programı kullanan sporcunun ilerlemesi
	 * başlangıçtan sayıldığı için düzenleme başlangıcı değiştirmemeli (G-74).
	 */
	@Test
	void updatingProgram_keepsItsStartDate() throws Exception {
		AppUser client = createUser("start_date@test.com", UserRole.CLIENT);
		TrainingBlock block = blockRepository.saveAndFlush(
				new TrainingBlock("Program", null, null, client, LocalDate.of(2026, 1, 5), LocalDate.of(2026, 2, 2)));
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/training/programs/personal/" + block.getId())
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(Map.of("name", "Duzenlendi", "start_date", "2026-09-23",
						"duration_weeks", 6, "workout_days", List.of()))))
			.andExpect(status().isOk());
		entityManager.flush();
		entityManager.clear();

		TrainingBlock after = blockRepository.findById(block.getId()).orElseThrow();
		assertThat(after.getStartDate()).isEqualTo(LocalDate.of(2026, 1, 5));
		assertThat(after.getEndDate()).isEqualTo(LocalDate.of(2026, 1, 5).plusWeeks(6));
	}

}
