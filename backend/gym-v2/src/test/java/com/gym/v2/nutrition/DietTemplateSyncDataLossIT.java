package com.gym.v2.nutrition;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.nutrition.entity.DietDay;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.Meal;
import com.gym.v2.nutrition.event.DietTemplateUpdatedEvent;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.service.DietProgramService;
import com.gym.v2.nutrition.service.DietTemplateService;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Diyet şablonu senkronizasyonunun sporcu verisini korumasını doğrular.
 * <p>
 * İki ayrı hata bu dosyada kapatılıyor:
 * </p>
 * <ul>
 * <li><b>Şablon değişikliği kopyayı yıkmamalı:</b> senkronizasyon, atanmış programın
 * günlerini/öğünlerini silip yeniden yaratırsa {@code meal_entry.planned_meal_id}
 * (yabancı anahtar kısıtı olmayan yumuşak referans) var olmayan kimliklere işaret eder ve
 * "planlanan öğün yendi mi" bilgisi sessizce kaybolur.</li>
 * <li><b>Sahiplenilen program koçtan kopmalı:</b> sporcu koçtan ayrılıp programı
 * sakladığında şablon bağı kesilmezse, eski koç şablonunu düzenlediğinde veya sildiğinde
 * sporcunun programı hâlâ etkilenir.</li>
 * </ul>
 */
class DietTemplateSyncDataLossIT extends IntegrationTestBase {

	@Autowired
	private DietTemplateService templateService;

	@Autowired
	private DietProgramService programService;

	@Autowired
	private DietProgramRepository programRepository;

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

	private void linkClientToCoach(AppUser clientUser, AppUser coachUser) {
		ClientEntity profile = new ClientEntity();
		profile.setUser(clientUser);
		profile.setFullName("Test Sporcu");
		profile.setCoachId(coachUser.getId());
		clientRepository.saveAndFlush(profile);
	}

	/** Koç şablonu oluşturup sporcuya atar, atanan kopyanın kimliğini döner. */
	private Long assignFreshTemplate(AppUser coach, AppUser client, String templateName) {
		actingAs(coach);
		Long templateId = templateService.createTemplate(templateName).id();
		entityManager.flush();
		entityManager.clear();

		actingAs(coach);
		Long assignedId = templateService.assignTemplateToClient(templateId, client.getId()).id();
		entityManager.flush();
		entityManager.clear();
		return assignedId;
	}

	private List<Long> mealIdsOf(Long programId) {
		return programRepository.findById(programId)
			.orElseThrow()
			.getDietDays()
			.stream()
			.sorted(Comparator.comparing(DietDay::getDayOrder))
			.flatMap(day -> day.getMeals().stream())
			.map(Meal::getId)
			.sorted()
			.toList();
	}

	@Test
	void templateUpdate_doesNotRecreateAssignedProgramRows() {
		AppUser coach = createUser("diet_sync_coach@test.com", UserRole.COACH);
		AppUser client = createUser("diet_sync_client@test.com", UserRole.CLIENT);
		linkClientToCoach(client, coach);

		Long assignedId = assignFreshTemplate(coach, client, "Kutle Sablonu");
		List<Long> mealIdsBefore = mealIdsOf(assignedId);
		entityManager.clear();

		assertThat(mealIdsBefore).as("ön koşul: atanan programda öğünler oluşmuş olmalı").isNotEmpty();

		// Koç şablonda bir hedefi değiştirir → senkronizasyon olayı tetiklenir.
		Long templateId = programRepository.findById(assignedId).orElseThrow().getOriginalTemplateId();
		DietProgram template = programRepository.findById(templateId).orElseThrow();
		template.setTargetCalories(new BigDecimal("2500"));
		templateService.syncTemplateUpdatesToAssignments(new DietTemplateUpdatedEvent(templateId));
		entityManager.flush();
		entityManager.clear();

		assertThat(mealIdsOf(assignedId))
			.as("öğün kimlikleri korunmalı; değişirse meal_entry.planned_meal_id boşa düşer")
			.isEqualTo(mealIdsBefore);
		assertThat(programRepository.findById(assignedId).orElseThrow().getTargetCalories())
			.as("şablondaki değişiklik yine de sporcuya yansımalı")
			.isEqualByComparingTo(new BigDecimal("2500"));
	}

	@Test
	void keepingOrphanedProgram_seversTheTemplateLink() {
		AppUser coach = createUser("diet_orphan_coach@test.com", UserRole.COACH);
		AppUser client = createUser("diet_orphan_client@test.com", UserRole.CLIENT);
		linkClientToCoach(client, coach);

		Long assignedId = assignFreshTemplate(coach, client, "Ayrilik Sablonu");
		Long templateId = programRepository.findById(assignedId).orElseThrow().getOriginalTemplateId();
		assertThat(templateId).as("ön koşul: kopya şablona bağlı olmalı").isNotNull();
		entityManager.clear();

		// Sporcu koçtan ayrılır ve programı saklamayı seçer.
		actingAs(client);
		programService.approveOrphanedDietProgram(assignedId, true);
		entityManager.flush();
		entityManager.clear();

		assertThat(programRepository.findById(assignedId).orElseThrow().getOriginalTemplateId())
			.as("sahiplenilen program eski koçun şablonuna bağlı kalmamalı")
			.isNull();
	}

	@Test
	void deletingTemplate_doesNotDeleteAProgramTheStudentChoseToKeep() {
		AppUser coach = createUser("diet_del_coach@test.com", UserRole.COACH);
		AppUser client = createUser("diet_del_client@test.com", UserRole.CLIENT);
		linkClientToCoach(client, coach);

		Long assignedId = assignFreshTemplate(coach, client, "Silinecek Sablon");
		Long templateId = programRepository.findById(assignedId).orElseThrow().getOriginalTemplateId();
		entityManager.clear();

		actingAs(client);
		programService.approveOrphanedDietProgram(assignedId, true);
		entityManager.flush();
		entityManager.clear();

		// Eski koç kendi şablonunu siler.
		actingAs(coach);
		programService.deleteProgram(templateId);
		entityManager.flush();
		entityManager.clear();

		assertThat(programRepository.findById(assignedId))
			.as("sporcunun saklamayı seçtiği program, eski koçun şablonuyla birlikte silinmemeli")
			.isPresent();
	}

}
