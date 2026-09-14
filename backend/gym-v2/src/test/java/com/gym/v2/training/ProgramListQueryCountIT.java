package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.service.TrainingBlockService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Supplier;
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
 * Program listelerinin sorgu maliyeti.
 * <p>
 * Antrenman programı üç katmanlı bir ağaçtır: program → gün → egzersiz. Liste ekranları
 * bu ağacın tamamını DTO'ya çevirdiği için, katmanlardan biri tembel bırakılırsa sorgu
 * sayısı program (veya gün) sayısıyla birlikte büyür.
 * </p>
 * <p>
 * Sabit eşik yerine büyüme ölçülür: aynı iş az veriyle ve çok veriyle yapılıp sorgu
 * sayıları karşılaştırılır.
 * </p>
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class ProgramListQueryCountIT extends IntegrationTestBase {

	@Autowired
	private TrainingBlockService trainingBlockService;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	/**
	 * Ölçümden önce kalıcılık bağlamı boşaltılır; aksi hâlde ikinci ölçüm birincinin
	 * belleğe aldığı nesneleri kullanır ve N+1 görünmez olur.
	 */
	private long queryCountFor(String email, Supplier<List<?>> call) {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(email, null, List.of()));
		call.get();

		return statistics().getPrepareStatementCount();
	}

	private Exercise newExercise(String name) {
		Exercise exercise = new Exercise();
		exercise.setName(name);
		exercise.setMuscleGroup(MuscleGroup.CHEST);
		exercise.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return exerciseRepository.saveAndFlush(exercise);
	}

	/** Her programda 2 gün, her günde 2 egzersiz bulunur. */
	private void seedBlocks(AppUser coach, AppUser client, boolean template, int count, String namePrefix) {
		Exercise first = newExercise(namePrefix + "-ex1");
		Exercise second = newExercise(namePrefix + "-ex2");

		for (int i = 0; i < count; i++) {
			TrainingBlock block = new TrainingBlock(namePrefix + i, "Aciklama", coach, client, LocalDate.of(2026, 1, 1),
					LocalDate.of(2026, 2, 1));
			block.setIsTemplate(template);

			List<WorkoutDay> days = new ArrayList<>();
			for (int d = 0; d < 2; d++) {
				WorkoutDay day = new WorkoutDay(block, "Gun " + d, d + 1);
				day.setExercises(new ArrayList<>(
						List.of(new WorkoutExercise(day, first, 3, "10", BigDecimal.TEN, 60, null, 0, false),
								new WorkoutExercise(day, second, 3, "12", BigDecimal.TEN, 60, null, 1, false))));
				days.add(day);
			}
			block.setWorkoutDays(days);
			blockRepository.saveAndFlush(block);
		}
	}

	@Test
	void getCoachTemplates_queryCountDoesNotGrowWithTemplateCount() {
		AppUser lightCoach = createUser("tpl_light@test.com", UserRole.COACH);
		AppUser heavyCoach = createUser("tpl_heavy@test.com", UserRole.COACH);
		seedBlocks(lightCoach, null, true, 1, "light");
		seedBlocks(heavyCoach, null, true, 4, "heavy");

		long lightQueries = queryCountFor(lightCoach.getEmail(), () -> trainingBlockService.getCoachTemplates());
		long heavyQueries = queryCountFor(heavyCoach.getEmail(), () -> trainingBlockService.getCoachTemplates());

		assertThat(heavyQueries)
			.as("1 şablon %d sorgu, 4 şablon %d sorgu ürettiyse maliyet veriyle büyüyor", lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getCoachAssignedPrograms_queryCountDoesNotGrowWithProgramCount() {
		AppUser lightCoach = createUser("asg_light@test.com", UserRole.COACH);
		AppUser heavyCoach = createUser("asg_heavy@test.com", UserRole.COACH);
		AppUser client = createUser("asg_client@test.com", UserRole.CLIENT);
		seedBlocks(lightCoach, client, false, 1, "alight");
		seedBlocks(heavyCoach, client, false, 4, "aheavy");

		long lightQueries = queryCountFor(lightCoach.getEmail(), () -> trainingBlockService.getCoachAssignedPrograms());
		long heavyQueries = queryCountFor(heavyCoach.getEmail(), () -> trainingBlockService.getCoachAssignedPrograms());

		assertThat(heavyQueries)
			.as("1 program %d sorgu, 4 program %d sorgu ürettiyse maliyet veriyle büyüyor", lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getMyActivePrograms_queryCountDoesNotGrowWithProgramCount() {
		AppUser lightClient = createUser("own_light@test.com", UserRole.CLIENT);
		AppUser heavyClient = createUser("own_heavy@test.com", UserRole.CLIENT);
		seedBlocks(null, lightClient, false, 1, "olight");
		seedBlocks(null, heavyClient, false, 4, "oheavy");

		long lightQueries = queryCountFor(lightClient.getEmail(), () -> trainingBlockService.getMyActivePrograms());
		long heavyQueries = queryCountFor(heavyClient.getEmail(), () -> trainingBlockService.getMyActivePrograms());

		assertThat(heavyQueries)
			.as("1 program %d sorgu, 4 program %d sorgu ürettiyse maliyet veriyle büyüyor", lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	/**
	 * Şablondan türetilmiş programlarda ekstra bir maliyet var: her program için "kaynak
	 * şablon hâlâ duruyor mu" kontrolü yapılıyor. Bu kontrol program başına ayrı sorguyla
	 * yapılırsa liste yine veriyle birlikte pahalılaşır.
	 */
	@Test
	void getMyActivePrograms_templateCheckDoesNotQueryPerProgram() {
		AppUser lightClient = createUser("tmpl_light@test.com", UserRole.CLIENT);
		AppUser heavyClient = createUser("tmpl_heavy@test.com", UserRole.CLIENT);
		seedBlocksFromTemplate(lightClient, 1, "tlight");
		seedBlocksFromTemplate(heavyClient, 4, "theavy");

		long lightQueries = queryCountFor(lightClient.getEmail(), () -> trainingBlockService.getMyActivePrograms());
		long heavyQueries = queryCountFor(heavyClient.getEmail(), () -> trainingBlockService.getMyActivePrograms());

		assertThat(heavyQueries)
			.as("1 program %d sorgu, 4 program %d sorgu ürettiyse şablon kontrolü program başına sorguluyor",
					lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getMyActivePrograms_marksProgramsWhoseTemplateWasDeleted() {
		AppUser client = createUser("orphan_check@test.com", UserRole.CLIENT);
		seedBlocksFromTemplate(client, 1, "orphan");

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(client.getEmail(), null, List.of()));
		var programs = trainingBlockService.getMyActivePrograms();

		// Sorguyu topluya çevirmek "şablonu silinmiş" işaretini bozmamalı:
		// var olan şablona bağlı program sahipsiz sayılmamalı.
		assertThat(programs).hasSize(1);
		assertThat(programs.getFirst().isOrphaned()).isFalse();
	}

	@Test
	void getMyActivePrograms_deletedTemplateMarksProgramAsOrphaned() {
		AppUser client = createUser("orphan_gone@test.com", UserRole.CLIENT);
		seedBlocksFromTemplate(client, 1, "gone");
		// Programın türediği şablon artık yok.
		blockRepository.findByClientId(client.getId()).forEach(b -> b.setTemplateId(999_999L));
		entityManager.flush();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(client.getEmail(), null, List.of()));
		var programs = trainingBlockService.getMyActivePrograms();

		assertThat(programs.getFirst().isOrphaned()).isTrue();
	}

	/** Sporcuya, gerçekten var olan bir şablondan türetilmiş programlar kurar. */
	private void seedBlocksFromTemplate(AppUser client, int count, String namePrefix) {
		TrainingBlock template = new TrainingBlock(namePrefix + "-tpl", "Sablon", null, null, LocalDate.of(2026, 1, 1),
				LocalDate.of(2026, 2, 1));
		template.setIsTemplate(true);
		TrainingBlock savedTemplate = blockRepository.saveAndFlush(template);

		seedBlocks(null, client, false, count, namePrefix);
		blockRepository.findByClientId(client.getId()).forEach(b -> b.setTemplateId(savedTemplate.getId()));
		entityManager.flush();
	}

	@Test
	void programList_returnsEveryDayAndExercise() {
		AppUser coach = createUser("tpl_data@test.com", UserRole.COACH);
		seedBlocks(coach, null, true, 3, "data");

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(coach.getEmail(), null, List.of()));
		var templates = trainingBlockService.getCoachTemplates();

		// Sorgu sayısını düşürmek veriyi eksiltmemeli.
		assertThat(templates).hasSize(3);
		assertThat(templates).allSatisfy(block -> {
			assertThat(block.workoutDays()).hasSize(2);
			assertThat(block.workoutDays()).allSatisfy(day -> assertThat(day.exercises()).hasSize(2));
		});
	}

}
