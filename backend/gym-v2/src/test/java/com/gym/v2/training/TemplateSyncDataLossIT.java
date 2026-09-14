package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.dto.WorkoutDayDTO;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.entity.WorkoutLog;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.service.TrainingBlockService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Koç şablonunu düzenlediğinde, o şablondan atanmış programların sporcuya ait verisi
 * korunmalıdır.
 * <p>
 * Bu testin varlık sebebi somut bir zincirdir: atama sırasında günler <b>kopyalanır</b>
 * (yeni kimliklerle), şablon düzenlenince aynı DTO atanmış programlara uygulanır ve
 * kimlikler eşleşmediği için sporcunun günleri koleksiyondan atılır. Koleksiyon
 * {@code cascade = ALL, orphanRemoval = true} olduğundan bu bir <b>veritabanı
 * silmesidir</b>; {@code workout_logs.workout_exercise_id} de {@code ON DELETE CASCADE}
 * olduğu için sporcunun antrenman geçmişi birlikte gider.
 * </p>
 * <p>
 * Kısacası: koçun şablon adını değiştirmesi, öğrencilerinin kaldırdığı ağırlıkları
 * silmemelidir.
 * </p>
 */
class TemplateSyncDataLossIT extends IntegrationTestBase {

	@Autowired
	private TrainingBlockService trainingBlockService;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@Autowired
	private WorkoutLogRepository logRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private void actingAs(AppUser user) {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
	}

	private Exercise newExercise(String name) {
		Exercise exercise = new Exercise();
		exercise.setName(name);
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		exercise.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return exerciseRepository.saveAndFlush(exercise);
	}

	private ClientEntity linkClientToCoach(AppUser clientUser, AppUser coachUser) {
		// Kimlik @MapsId ile user'dan türetilir; userId elle set edilirse Hibernate kaydı
		// "yeni değil" sayıp merge'e gider ve kimlik boş kalır.
		ClientEntity profile = new ClientEntity();
		profile.setUser(clientUser);
		profile.setFullName("Test Sporcu");
		profile.setCoachId(coachUser.getId());
		return clientRepository.saveAndFlush(profile);
	}

	/** İki günlü, gün başına bir egzersizli bir koç şablonu kurar. */
	private TrainingBlock seedTemplate(AppUser coach, Exercise exercise) {
		TrainingBlock template = new TrainingBlock("Push Pull Legs", "Aciklama", coach, null, LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 2, 1));
		template.setIsTemplate(true);

		List<WorkoutDay> days = new ArrayList<>();
		for (int d = 0; d < 2; d++) {
			WorkoutDay day = new WorkoutDay(template, "Gun " + d, d + 1);
			day.setExercises(new ArrayList<>(
					List.of(new WorkoutExercise(day, exercise, 3, "10", BigDecimal.TEN, 60, null, 0, false))));
			days.add(day);
		}
		template.setWorkoutDays(days);
		return blockRepository.saveAndFlush(template);
	}

	/**
	 * Şablonun kendi içeriğini, adı değişmiş hâlde DTO'ya çevirir (koçun düzenleme
	 * isteği).
	 */
	private TrainingBlockDTO renameRequestFor(TrainingBlock template, String newName) {
		List<WorkoutDayDTO> dayDtos = template.getWorkoutDays().stream().map(day -> {
			List<WorkoutExerciseDTO> exerciseDtos = day.getExercises()
				.stream()
				.map(we -> new WorkoutExerciseDTO(we.getId(), we.getExercise().getId(), we.getExercise().getName(),
						null, we.getTargetSets(), we.getTargetReps(), we.getTargetWeight(), we.getRestTimeSeconds(),
						we.getSupersetGroupId(), we.getOrderIndex(), null, we.getIsToFailure(), null))
				.toList();
			return new WorkoutDayDTO(day.getId(), day.getName(), day.getDayOrder(), day.getIsMagnetEnabled(),
					exerciseDtos);
		}).toList();

		return new TrainingBlockDTO(template.getId(), newName, template.getDescription(), null, null, null, null,
				template.getStartDate(), template.getEndDate(), template.getIsActive(), template.getDurationWeeks(),
				dayDtos, false, true, false);
	}

	@Test
	void editingTemplate_doesNotDeleteStudentsWorkoutHistory() {
		AppUser coach = createUser("tpl_sync_coach@test.com", UserRole.COACH);
		AppUser client = createUser("tpl_sync_client@test.com", UserRole.CLIENT);
		linkClientToCoach(client, coach);
		Exercise exercise = newExercise("Bench Press");
		TrainingBlock template = seedTemplate(coach, exercise);

		// Koç şablonu sporcuya atar: günler yeni kimliklerle kopyalanır.
		actingAs(coach);
		Long assignedId = trainingBlockService.assignTemplateToClient(template.getId(), client.getId()).id();
		entityManager.flush();
		entityManager.clear();

		// Sporcu bir set kaydeder.
		TrainingBlock assigned = blockRepository.findById(assignedId).orElseThrow();
		WorkoutExercise loggedExercise = assigned.getWorkoutDays().getFirst().getExercises().getFirst();
		WorkoutLog log = new WorkoutLog(loggedExercise, 1, new BigDecimal("60.00"), 8, 7, 45);
		log.onPersist(Instant.parse("2026-02-01T10:00:00Z"));
		logRepository.saveAndFlush(log);
		Long loggedExerciseId = loggedExercise.getId();
		entityManager.clear();

		assertThat(logRepository.findByWorkoutExerciseIdOrderBySetIndexAsc(loggedExerciseId))
			.as("ön koşul: set kaydı oluşmuş olmalı")
			.hasSize(1);

		// Koç yalnızca şablonun ADINI değiştirir.
		TrainingBlock freshTemplate = blockRepository.findById(template.getId()).orElseThrow();
		actingAs(coach);
		trainingBlockService.updateCoachTemplate(template.getId(), renameRequestFor(freshTemplate, "Yeni Ad"));
		entityManager.flush();
		entityManager.clear();

		assertThat(logRepository.findByWorkoutExerciseIdOrderBySetIndexAsc(loggedExerciseId))
			.as("koç şablonun adını değiştirdi; sporcunun antrenman geçmişi silinmemeliydi")
			.hasSize(1);
	}

	@Test
	void editingTemplate_keepsStudentProgramStructureAndAppliesTheChange() {
		AppUser coach = createUser("tpl_keep_coach@test.com", UserRole.COACH);
		AppUser client = createUser("tpl_keep_client@test.com", UserRole.CLIENT);
		linkClientToCoach(client, coach);
		Exercise exercise = newExercise("Squat");
		TrainingBlock template = seedTemplate(coach, exercise);

		actingAs(coach);
		Long assignedId = trainingBlockService.assignTemplateToClient(template.getId(), client.getId()).id();
		entityManager.flush();
		entityManager.clear();

		List<Long> dayIdsBefore = blockRepository.findById(assignedId)
			.orElseThrow()
			.getWorkoutDays()
			.stream()
			.map(WorkoutDay::getId)
			.sorted()
			.toList();
		entityManager.clear();

		TrainingBlock freshTemplate = blockRepository.findById(template.getId()).orElseThrow();
		actingAs(coach);
		trainingBlockService.updateCoachTemplate(template.getId(), renameRequestFor(freshTemplate, "Guncel Ad"));
		entityManager.flush();
		entityManager.clear();

		TrainingBlock assignedAfter = blockRepository.findById(assignedId).orElseThrow();

		// Güncelleme sporcuya yansımalı...
		assertThat(assignedAfter.getName()).isEqualTo("Guncel Ad");
		// ...ama satırlar yeniden yaratılarak değil, yerinde güncellenerek.
		assertThat(assignedAfter.getWorkoutDays().stream().map(WorkoutDay::getId).sorted().toList())
			.as("gün kimlikleri korunmalı; değişirse geçmiş kayıtların bağı kopar")
			.isEqualTo(dayIdsBefore);
		assertThat(assignedAfter.getWorkoutDays()).hasSize(2);
		assertThat(assignedAfter.getWorkoutDays()).allSatisfy(day -> assertThat(day.getExercises()).hasSize(1));
	}

}
