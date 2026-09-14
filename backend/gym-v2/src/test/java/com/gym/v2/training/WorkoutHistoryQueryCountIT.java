package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.entity.WorkoutLog;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.service.WorkoutSessionService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Antrenman geçmişinin sorgu maliyeti.
 * <p>
 * Bu ekran, kullanıcının tüm idman oturumlarını setleriyle birlikte listeler. Oturumlar
 * tek sorguyla gelse bile her oturumun logları, her logun egzersizi ayrı ayrı çekilirse
 * sorgu sayısı veriyle birlikte büyür (N+1) ve ekran kullanıcı uygulamayı kullandıkça
 * yavaşlar.
 * </p>
 * <p>
 * Test sabit bir sorgu sayısı beklemez — böyle bir eşik her sorgu değişikliğinde kırılır
 * ve gerçek soruyu ölçmez. Ölçülen şey şudur: <b>veri artınca sorgu sayısı artıyor
 * mu?</b> Aynı işi 1 oturumla ve 4 oturumla yapıp iki sayıyı karşılaştırır.
 * </p>
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class WorkoutHistoryQueryCountIT extends IntegrationTestBase {

	@Autowired
	private WorkoutSessionService workoutSessionService;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@Autowired
	private WorkoutSessionRepository sessionRepository;

	@PersistenceContext
	private EntityManager entityManager;

	private static final int LOGS_PER_SESSION = 3;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	/**
	 * Servisi çağırırken üretilen SQL sayısını ölçer.
	 * <p>
	 * Ölçümden önce kalıcılık bağlamı boşaltılır: aksi hâlde ikinci ölçüm birinci ölçümün
	 * belleğe aldığı nesneleri kullanır ve N+1 görünmez olur.
	 * </p>
	 */
	private long queryCountFor(String email) {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(email, null, List.of()));
		workoutSessionService.getWorkoutHistory();

		return statistics().getPrepareStatementCount();
	}

	/** Verilen sayıda oturumu, her biri {@value #LOGS_PER_SESSION} setli olarak kurar. */
	private AppUser seedUserWithSessions(String email, int sessionCount) {
		AppUser user = createUser(email, UserRole.CLIENT);

		Exercise exercise = new Exercise();
		exercise.setName("Bench Press " + email);
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		exercise.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		exercise = exerciseRepository.saveAndFlush(exercise);

		TrainingBlock block = new TrainingBlock("Program", "Aciklama", null, user, LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 2, 1));
		WorkoutDay day = new WorkoutDay(block, "Gun 1", 1);
		WorkoutExercise workoutExercise = new WorkoutExercise(day, exercise, 3, "10", BigDecimal.TEN, 60, null, 0,
				false);
		day.setExercises(new ArrayList<>(List.of(workoutExercise)));
		block.setWorkoutDays(new ArrayList<>(List.of(day)));
		blockRepository.saveAndFlush(block);

		for (int i = 0; i < sessionCount; i++) {
			WorkoutSession session = new WorkoutSession(user, "Gun 1", 3600);
			session.onPersist(Instant.parse("2026-01-0" + (i + 1) + "T10:00:00Z"));
			for (int setIndex = 1; setIndex <= LOGS_PER_SESSION; setIndex++) {
				WorkoutLog log = new WorkoutLog(workoutExercise, setIndex, BigDecimal.valueOf(60), 10, 8, null);
				log.onPersist(Instant.parse("2026-01-0" + (i + 1) + "T10:00:00Z"));
				session.addLog(log);
			}
			sessionRepository.saveAndFlush(session);
		}
		return user;
	}

	@Test
	void getWorkoutHistory_queryCountDoesNotGrowWithSessionCount() {
		AppUser light = seedUserWithSessions("history_light@test.com", 1);
		AppUser heavy = seedUserWithSessions("history_heavy@test.com", 4);

		long lightQueries = queryCountFor(light.getEmail());
		long heavyQueries = queryCountFor(heavy.getEmail());

		assertThat(heavyQueries)
			.as("1 oturum %d sorgu, 4 oturum %d sorgu ürettiyse maliyet veriyle birlikte büyüyor (N+1)", lightQueries,
					heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getWorkoutHistory_returnsEverySessionWithItsSets() {
		AppUser user = seedUserWithSessions("history_data@test.com", 4);

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		var history = workoutSessionService.getWorkoutHistory();

		// Sorgu sayısını düşürmek veriyi eksiltmemeli.
		assertThat(history).hasSize(4);
		assertThat(history).allSatisfy(session -> assertThat(session.logs()).hasSize(LOGS_PER_SESSION));
		assertThat(history.getFirst().logs().getFirst().exerciseName()).isNotNull();
	}

}
