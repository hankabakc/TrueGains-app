package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WeeklyProgress;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WeeklyProgressRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * K1-07: Antrenman oturumu kaydında program ve gün sahipliği (IDOR) gerçek veritabanı
 * sorgularıyla doğrulanır.
 * <p>
 * Başka bir sporcunun programına veya gününe ait kimliklerle oturum kaydedilemez (404
 * döner); reddedilen isteklerde hiçbir veri kalıcı olarak saklanmaz.
 * </p>
 */
class WorkoutSessionOwnershipIT extends IntegrationTestBase {

	private static final long LOCAL_EXERCISE_ID = -501;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private WorkoutSessionRepository sessionRepository;

	@Autowired
	private WeeklyProgressRepository weeklyProgressRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private Exercise savedExercise() {
		Exercise exercise = new Exercise();
		exercise.setName("Bench Press");
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		exercise.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return exerciseRepository.saveAndFlush(exercise);
	}

	private void createQueuedProgram(AppUser user, String localId, Exercise exercise) throws Exception {
		Map<String, Object> workoutExercise = Map.of("id", LOCAL_EXERCISE_ID, "exercise_id", exercise.getId(),
				"target_sets", 3, "target_reps", "10", "order_index", 0);
		Map<String, Object> day = Map.of("id", -11, "name", "Pazartesi", "day_order", 1, "exercises",
				List.of(workoutExercise));
		String body = objectMapper.writeValueAsString(Map.of("name", "Sahip Program", "start_date", "2026-09-23",
				"duration_weeks", 4, "workout_days", List.of(day), "local_id", localId));
		mockMvc
			.perform(post("/api/v1/training/programs/personal").header("Authorization", bearerTokenFor(user))
				.contentType(MediaType.APPLICATION_JSON)
				.content(body))
			.andExpect(status().isOk());
	}

	private String sessionJson(Long trainingBlockId, Long workoutDayId) throws Exception {
		Map<String, Object> body = new HashMap<>();
		body.put("workoutDayName", "Pazartesi");
		body.put("totalSeconds", 600);
		body.put("logs", List.of());
		if (trainingBlockId != null) {
			body.put("trainingBlockId", trainingBlockId);
		}
		if (workoutDayId != null) {
			body.put("workoutDayId", workoutDayId);
		}
		return objectMapper.writeValueAsString(body);
	}

	@Test
	void session_withAnotherClientsTrainingBlockId_isNotFoundAndNothingStored() throws Exception {
		AppUser owner = createUser("session_owner_block@test.com", UserRole.CLIENT);
		AppUser other = createUser("session_other_block@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "sahip-prog-1", savedExercise());

		TrainingBlock ownerBlock = blockRepository.findByClientIdAndLocalId(owner.getId(), "sahip-prog-1")
			.orElseThrow();
		entityManager.clear();

		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(sessionJson(ownerBlock.getId(), null)))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(sessionRepository.findHistoryWithLogs(other.getId())).isEmpty();
		assertThat(weeklyProgressRepository.findByUserIdOrderByWeekStartDateDesc(other.getId())).isEmpty();
	}

	@Test
	void session_withAnotherClientsWorkoutDayId_isNotFoundAndNothingStored() throws Exception {
		AppUser owner = createUser("session_owner_day@test.com", UserRole.CLIENT);
		AppUser other = createUser("session_other_day@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "sahip-prog-2", savedExercise());

		TrainingBlock ownerBlock = blockRepository.findByClientIdAndLocalId(owner.getId(), "sahip-prog-2")
			.orElseThrow();
		WorkoutDay ownerDay = ownerBlock.getWorkoutDays().getFirst();
		entityManager.clear();

		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(sessionJson(null, ownerDay.getId())))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(sessionRepository.findHistoryWithLogs(other.getId())).isEmpty();
		assertThat(weeklyProgressRepository.findByUserIdOrderByWeekStartDateDesc(other.getId())).isEmpty();
	}

	@Test
	void session_withAnotherClientsProgramAndDay_isNotFoundAndNothingStored() throws Exception {
		AppUser owner = createUser("session_owner_both@test.com", UserRole.CLIENT);
		AppUser other = createUser("session_other_both@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "sahip-prog-3", savedExercise());

		TrainingBlock ownerBlock = blockRepository.findByClientIdAndLocalId(owner.getId(), "sahip-prog-3")
			.orElseThrow();
		WorkoutDay ownerDay = ownerBlock.getWorkoutDays().getFirst();
		entityManager.clear();

		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(sessionJson(ownerBlock.getId(), ownerDay.getId())))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(sessionRepository.findHistoryWithLogs(other.getId())).isEmpty();
		assertThat(weeklyProgressRepository.findByUserIdOrderByWeekStartDateDesc(other.getId())).isEmpty();
	}

	@Test
	void session_withOwnProgramAndDay_isStoredAndLinked() throws Exception {
		AppUser owner = createUser("session_owner_success@test.com", UserRole.CLIENT);
		createQueuedProgram(owner, "sahip-prog-4", savedExercise());

		TrainingBlock ownerBlock = blockRepository.findByClientIdAndLocalId(owner.getId(), "sahip-prog-4")
			.orElseThrow();
		WorkoutDay ownerDay = ownerBlock.getWorkoutDays().getFirst();
		entityManager.clear();

		mockMvc
			.perform(post("/api/v1/training/sessions").header("Authorization", bearerTokenFor(owner))
				.contentType(MediaType.APPLICATION_JSON)
				.content(sessionJson(ownerBlock.getId(), ownerDay.getId())))
			.andExpect(status().isOk());
		entityManager.flush();
		entityManager.clear();

		List<WorkoutSession> sessions = sessionRepository.findHistoryWithLogs(owner.getId());
		assertThat(sessions).hasSize(1);
		WorkoutSession session = sessions.getFirst();
		assertThat(session.getTrainingBlockId()).isEqualTo(ownerBlock.getId());
		assertThat(session.getWorkoutDayId()).isEqualTo(ownerDay.getId());

		List<WeeklyProgress> progressList = weeklyProgressRepository
			.findByUserIdOrderByWeekStartDateDesc(owner.getId());
		assertThat(progressList).hasSize(1);
	}

}
