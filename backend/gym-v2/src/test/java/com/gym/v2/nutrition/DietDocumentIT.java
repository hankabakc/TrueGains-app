package com.gym.v2.nutrition;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.nutrition.dto.BulkIngredientRequest;
import com.gym.v2.nutrition.dto.DietProgramDocumentRequest;
import com.gym.v2.nutrition.dto.UpdateNutritionGoalsRequest;
import com.gym.v2.nutrition.entity.DietDay;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.DietSource;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.Meal;
import com.gym.v2.nutrition.entity.MealIngredient;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.service.DietDocumentService;
import com.gym.v2.nutrition.service.DietProgramService;
import com.gym.v2.support.IntegrationTestBase;
import com.jayway.jsonpath.JsonPath;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * G-76: Diyet planı tek belge kaydetme ucu ve sürüm kilidi testleri.
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class DietDocumentIT extends IntegrationTestBase {

	@Autowired
	private DietDocumentService documentService;

	@Autowired
	private DietProgramService programService;

	@Autowired
	private DietProgramRepository programRepository;

	@Autowired
	private FoodRepository foodRepository;

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

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	private Food createFood(String name) {
		Food food = new Food(name, "g", BigDecimal.valueOf(100));
		food.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return foodRepository.saveAndFlush(food);
	}

	private DietProgram loadProgram(Long id) {
		return programRepository.findById(id).orElseThrow();
	}

	private Set<Long> mealIdsOf(DietProgram program) {
		return program.getDietDays()
			.stream()
			.flatMap(d -> d.getMeals().stream())
			.map(Meal::getId)
			.collect(Collectors.toSet());
	}

	private Long createProgramFor(AppUser client, String name) throws Exception {
		MvcResult res = mockMvc
			.perform(post("/api/v1/nutrition/diet/create").param("name", name)
				.param("isMain", "true")
				.header("Authorization", bearerTokenFor(client)))
			.andExpect(status().isOk())
			.andReturn();
		entityManager.flush();
		entityManager.clear();
		return ((Number) JsonPath.read(res.getResponse().getContentAsString(), "$.data.id")).longValue();
	}

	private Long addIngredientToMeal(AppUser client, Long mealId, Long foodId, BigDecimal amount) throws Exception {
		List<BulkIngredientRequest> reqs = List.of(new BulkIngredientRequest(foodId, null, amount, "ilk not", false));
		mockMvc
			.perform(post("/api/v1/nutrition/diet/meals/" + mealId + "/ingredients/bulk")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(reqs)))
			.andExpect(status().isOk());
		entityManager.flush();
		entityManager.clear();

		Meal meal = entityManager.find(Meal.class, mealId);
		return meal.getIngredients().get(meal.getIngredients().size() - 1).getId();
	}

	private Long addIngredientToFirstMeal(AppUser client, Long programId, Long foodId, BigDecimal amount)
			throws Exception {
		DietProgram program = loadProgram(programId);
		Long mealId = program.getDietDays().get(0).getMeals().get(0).getId();
		return addIngredientToMeal(client, mealId, foodId, amount);
	}

	private DietProgramDocumentRequest buildDocumentRequest(DietProgram program, String editId) {
		List<DietProgramDocumentRequest.DayDoc> dayDocs = new ArrayList<>();
		for (DietDay day : program.getDietDays()) {
			List<DietProgramDocumentRequest.MealDoc> mealDocs = new ArrayList<>();
			for (Meal meal : day.getMeals()) {
				List<DietProgramDocumentRequest.IngredientDoc> ingDocs = new ArrayList<>();
				for (MealIngredient ing : meal.getIngredients()) {
					Long foodId = ing.getFood() != null ? ing.getFood().getId() : null;
					Long recipeId = ing.getRecipe() != null ? ing.getRecipe().getId() : null;
					ingDocs.add(new DietProgramDocumentRequest.IngredientDoc(ing.getId(), foodId, recipeId,
							ing.getAmount(), ing.getNote(), ing.isIgnoreOverride()));
				}
				mealDocs.add(new DietProgramDocumentRequest.MealDoc(meal.getId(), ingDocs));
			}
			dayDocs.add(new DietProgramDocumentRequest.DayDoc(day.getId(), mealDocs));
		}
		UpdateNutritionGoalsRequest goals = new UpdateNutritionGoalsRequest(program.getTargetCalories(),
				program.getTargetProtein(), program.getTargetCarbs(), program.getTargetFat(), program.getTargetSugar(),
				program.getTargetFiber(), program.getTargetSodium(), program.getTargetCholesterol(),
				program.getTargetPotassium());
		return new DietProgramDocumentRequest(program.getVersion(), editId, program.getName(), goals, dayDocs);
	}

	@Test
	void document_changesAmountAndAddsIngredient_inPlace() throws Exception {
		AppUser client = createUser("doc_client1@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Plan");
		Food existingFood = createFood("Yulaf");
		Long existingIngId = addIngredientToFirstMeal(client, programId, existingFood.getId(),
				new BigDecimal("100.00"));

		Food newFood = createFood("Muz");

		DietProgram fresh = loadProgram(programId);
		Long oldVersion = fresh.getVersion();
		Set<Long> oldMealIds = mealIdsOf(fresh);

		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, null);
		List<DietProgramDocumentRequest.DayDoc> updatedDays = new ArrayList<>();
		for (int d = 0; d < baseReq.days().size(); d++) {
			DietProgramDocumentRequest.DayDoc dayDoc = baseReq.days().get(d);
			if (d == 0) {
				List<DietProgramDocumentRequest.MealDoc> updatedMeals = new ArrayList<>();
				for (int m = 0; m < dayDoc.meals().size(); m++) {
					DietProgramDocumentRequest.MealDoc mealDoc = dayDoc.meals().get(m);
					if (m == 0) {
						List<DietProgramDocumentRequest.IngredientDoc> updatedIngs = new ArrayList<>();
						DietProgramDocumentRequest.IngredientDoc existingDoc = mealDoc.ingredients().get(0);
						updatedIngs
							.add(new DietProgramDocumentRequest.IngredientDoc(existingDoc.id(), existingDoc.foodId(),
									existingDoc.recipeId(), new BigDecimal("150.00"), "yeni not", false));
						updatedIngs.add(new DietProgramDocumentRequest.IngredientDoc(null, newFood.getId(), null,
								new BigDecimal("50.00"), "muz notu", false));
						updatedMeals.add(new DietProgramDocumentRequest.MealDoc(mealDoc.id(), updatedIngs));
					}
					else {
						updatedMeals.add(mealDoc);
					}
				}
				updatedDays.add(new DietProgramDocumentRequest.DayDoc(dayDoc.id(), updatedMeals));
			}
			else {
				updatedDays.add(dayDoc);
			}
		}

		DietProgramDocumentRequest req = new DietProgramDocumentRequest(baseReq.version(), null, baseReq.name(),
				baseReq.goals(), updatedDays);

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.version").value(oldVersion + 1));

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getVersion()).isEqualTo(oldVersion + 1);
		assertThat(mealIdsOf(saved)).isEqualTo(oldMealIds);

		Meal firstMeal = saved.getDietDays().get(0).getMeals().get(0);
		assertThat(firstMeal.getIngredients()).hasSize(2);
		MealIngredient updatedExisting = firstMeal.getIngredients()
			.stream()
			.filter(i -> i.getId().equals(existingIngId))
			.findFirst()
			.orElseThrow();
		assertThat(updatedExisting.getAmount()).isEqualByComparingTo(new BigDecimal("150.00"));

		MealIngredient brandNew = firstMeal.getIngredients()
			.stream()
			.filter(i -> !i.getId().equals(existingIngId))
			.findFirst()
			.orElseThrow();
		assertThat(brandNew.getFood().getId()).isEqualTo(newFood.getId());
		assertThat(brandNew.getAmount()).isEqualByComparingTo(new BigDecimal("50.00"));
	}

	@Test
	void document_omittedMealAndIngredient_areDeleted_restUntouched() throws Exception {
		AppUser client = createUser("doc_client2@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Eski Ad");
		Food food = createFood("Yulaf");
		addIngredientToFirstMeal(client, programId, food.getId(), new BigDecimal("100.00"));

		DietProgram fresh = loadProgram(programId);
		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, "edit-del");

		List<DietProgramDocumentRequest.DayDoc> updatedDays = new ArrayList<>();
		for (int d = 0; d < baseReq.days().size(); d++) {
			DietProgramDocumentRequest.DayDoc dayDoc = baseReq.days().get(d);
			if (d == 0) {
				List<DietProgramDocumentRequest.MealDoc> updatedMeals = new ArrayList<>();
				for (DietProgramDocumentRequest.MealDoc mealDoc : dayDoc.meals()) {
					if (mealDoc.id().equals(fresh.getDietDays().get(0).getMeals().get(3).getId())) {
						continue;
					}
					if (mealDoc.id().equals(fresh.getDietDays().get(0).getMeals().get(0).getId())) {
						updatedMeals.add(new DietProgramDocumentRequest.MealDoc(mealDoc.id(), List.of()));
					}
					else {
						updatedMeals.add(mealDoc);
					}
				}
				updatedDays.add(new DietProgramDocumentRequest.DayDoc(dayDoc.id(), updatedMeals));
			}
			else {
				updatedDays.add(dayDoc);
			}
		}

		DietProgramDocumentRequest req = new DietProgramDocumentRequest(baseReq.version(), "edit-del", "Yeni Plan Adı",
				baseReq.goals(), updatedDays);

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req)))
			.andExpect(status().isOk());

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getName()).isEqualTo("Yeni Plan Adı");

		int totalMeals = saved.getDietDays().stream().mapToInt(d -> d.getMeals().size()).sum();
		assertThat(totalMeals).isEqualTo(27);

		assertThat(saved.getDietDays().get(0).getMeals().get(0).getIngredients()).isEmpty();

		for (int i = 1; i < 7; i++) {
			assertThat(saved.getDietDays().get(i).getMeals()).hasSize(4);
		}
	}

	@Test
	void document_withStaleVersion_isConflictAndNothingChanges() throws Exception {
		AppUser client = createUser("doc_client3@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Orijinal Ad");
		Food food = createFood("Yulaf");
		addIngredientToFirstMeal(client, programId, food.getId(), new BigDecimal("100.00"));

		DietProgram fresh = loadProgram(programId);
		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, "edit-stale");

		DietProgramDocumentRequest staleReq = new DietProgramDocumentRequest(fresh.getVersion() - 1, "edit-stale",
				"Degismis Ad", baseReq.goals(), baseReq.days());

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(staleReq)))
			.andExpect(status().isConflict());

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getName()).isEqualTo("Orijinal Ad");
		assertThat(saved.getDietDays().get(0).getMeals().get(0).getIngredients().get(0).getAmount())
			.isEqualByComparingTo(new BigDecimal("100.00"));
		int totalMeals = saved.getDietDays().stream().mapToInt(d -> d.getMeals().size()).sum();
		assertThat(totalMeals).isEqualTo(28);
	}

	@Test
	void document_resentWithSameEditId_returnsAppliedWithoutConflict() throws Exception {
		AppUser client = createUser("doc_client4@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Tekrar Ad");
		Food food = createFood("Yulaf");
		addIngredientToFirstMeal(client, programId, food.getId(), new BigDecimal("100.00"));

		DietProgram fresh = loadProgram(programId);
		Long initialVersion = fresh.getVersion();
		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, "belge-1");

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(baseReq)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.version").value(initialVersion + 1));

		entityManager.flush();
		entityManager.clear();

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(baseReq)))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.version").value(initialVersion + 1));

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getVersion()).isEqualTo(initialVersion + 1);
		assertThat(saved.getLastEditId()).isEqualTo("belge-1");
	}

	@Test
	void document_ofAnotherClientsProgram_isRejectedAndNothingChanges() throws Exception {
		AppUser owner = createUser("doc_owner5@test.com", UserRole.CLIENT);
		AppUser other = createUser("doc_other5@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(owner, "Sahip Plani");

		DietProgram fresh = loadProgram(programId);
		DietProgramDocumentRequest req = buildDocumentRequest(fresh, "edit-other");

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req)))
			.andExpect(status().isBadRequest());

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getName()).isEqualTo("Sahip Plani");
	}

	@Test
	void document_onCoachSourcedProgram_isRejectedForClient() throws Exception {
		AppUser coach = createUser("doc_coach6@test.com", UserRole.COACH);
		AppUser client = createUser("doc_client6@test.com", UserRole.CLIENT);

		DietProgram coachProg = new DietProgram(client, "Koc Plani", DietSource.COACH);
		coachProg.setCoach(coach);
		coachProg.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		programService.setDefaultGoals(coachProg);
		for (int i = 1; i <= 7; i++) {
			DietDay day = new DietDay(coachProg, i, "Gün " + i);
			day.getMeals().add(new Meal(day, MealType.KAHVALTI, 0));
			coachProg.getDietDays().add(day);
		}
		DietProgram saved = programRepository.saveAndFlush(coachProg);
		entityManager.clear();

		DietProgram fresh = loadProgram(saved.getId());
		DietProgramDocumentRequest req = buildDocumentRequest(fresh, "edit-coach-source");

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + saved.getId() + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req)))
			.andExpect(status().isBadRequest());

		entityManager.flush();
		entityManager.clear();

		DietProgram after = loadProgram(saved.getId());
		assertThat(after.getName()).isEqualTo("Koc Plani");
	}

	@Test
	void document_withIngredientOfAnotherMeal_isBadRequestAndNothingChanges() throws Exception {
		AppUser client = createUser("doc_client7@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Plan 7");
		Food food1 = createFood("Yulaf");
		Food food2 = createFood("Muz");

		DietProgram fresh = loadProgram(programId);
		Long meal1Id = fresh.getDietDays().get(0).getMeals().get(0).getId();
		Long meal2Id = fresh.getDietDays().get(0).getMeals().get(1).getId();

		addIngredientToMeal(client, meal1Id, food1.getId(), new BigDecimal("100.00"));
		Long meal2IngId = addIngredientToMeal(client, meal2Id, food2.getId(), new BigDecimal("80.00"));

		fresh = loadProgram(programId);
		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, "edit-cross");

		List<DietProgramDocumentRequest.DayDoc> updatedDays = new ArrayList<>();
		for (int d = 0; d < baseReq.days().size(); d++) {
			DietProgramDocumentRequest.DayDoc dayDoc = baseReq.days().get(d);
			if (d == 0) {
				List<DietProgramDocumentRequest.MealDoc> updatedMeals = new ArrayList<>();
				for (DietProgramDocumentRequest.MealDoc mealDoc : dayDoc.meals()) {
					if (mealDoc.id().equals(meal1Id)) {
						List<DietProgramDocumentRequest.IngredientDoc> corruptedIngs = new ArrayList<>(
								mealDoc.ingredients());
						corruptedIngs.add(new DietProgramDocumentRequest.IngredientDoc(meal2IngId, food2.getId(), null,
								new BigDecimal("50.00"), "hatali", false));
						updatedMeals.add(new DietProgramDocumentRequest.MealDoc(mealDoc.id(), corruptedIngs));
					}
					else {
						updatedMeals.add(mealDoc);
					}
				}
				updatedDays.add(new DietProgramDocumentRequest.DayDoc(dayDoc.id(), updatedMeals));
			}
			else {
				updatedDays.add(dayDoc);
			}
		}

		DietProgramDocumentRequest badReq = new DietProgramDocumentRequest(baseReq.version(), "edit-cross",
				baseReq.name(), baseReq.goals(), updatedDays);

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(badReq)))
			.andExpect(status().isBadRequest());

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getDietDays().get(0).getMeals().get(0).getIngredients()).hasSize(1);
		assertThat(saved.getDietDays().get(0).getMeals().get(1).getIngredients()).hasSize(1);
	}

	@Test
	void document_withMissingDay_isBadRequestAndNothingChanges() throws Exception {
		AppUser client = createUser("doc_client8@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Plan 8");

		DietProgram fresh = loadProgram(programId);
		DietProgramDocumentRequest baseReq = buildDocumentRequest(fresh, "edit-missing-day");

		List<DietProgramDocumentRequest.DayDoc> sixDays = baseReq.days().subList(0, 6);
		DietProgramDocumentRequest req = new DietProgramDocumentRequest(baseReq.version(), "edit-missing-day",
				"Eksik Gun", baseReq.goals(), sixDays);

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req)))
			.andExpect(status().isBadRequest());

		entityManager.flush();
		entityManager.clear();

		DietProgram saved = loadProgram(programId);
		assertThat(saved.getName()).isEqualTo("Plan 8");
		assertThat(saved.getDietDays()).hasSize(7);
	}

	@Test
	void ingredientEndpoint_advancesVersion_soStaleDocumentConflicts() throws Exception {
		AppUser client = createUser("doc_client9@test.com", UserRole.CLIENT);
		Long programId = createProgramFor(client, "Plan 9");
		Food food = createFood("Yulaf");
		Long ingId = addIngredientToFirstMeal(client, programId, food.getId(), new BigDecimal("100.00"));

		DietProgram fresh = loadProgram(programId);
		Long initialVersion = fresh.getVersion();
		DietProgramDocumentRequest staleDoc = buildDocumentRequest(fresh, "edit-stale-after-part");

		mockMvc
			.perform(put("/api/v1/nutrition/diet/meals/ingredients/" + ingId).param("amount", "200.00")
				.header("Authorization", bearerTokenFor(client)))
			.andExpect(status().isOk());

		entityManager.flush();
		entityManager.clear();

		DietProgram updatedProgram = loadProgram(programId);
		assertThat(updatedProgram.getVersion()).isEqualTo(initialVersion + 1);

		mockMvc
			.perform(put("/api/v1/nutrition/diet/" + programId + "/document")
				.header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(staleDoc)))
			.andExpect(status().isConflict());
	}

	@Test
	void document_newIngredientCount_doesNotChangeQueryCount() throws Exception {
		AppUser client = createUser("doc_client10@test.com", UserRole.CLIENT);
		Long programId1 = createProgramFor(client, "Plan Q1");
		Long programId2 = createProgramFor(client, "Plan Q2");

		Food food1 = createFood("Food Q1");
		Food food2 = createFood("Food Q2");
		Food food3 = createFood("Food Q3");
		Food food4 = createFood("Food Q4");

		DietProgram fresh1 = loadProgram(programId1);
		DietProgramDocumentRequest baseReq1 = buildDocumentRequest(fresh1, "edit-q1");

		List<DietProgramDocumentRequest.DayDoc> days1 = new ArrayList<>();
		for (int d = 0; d < baseReq1.days().size(); d++) {
			var day = baseReq1.days().get(d);
			if (d == 0) {
				List<DietProgramDocumentRequest.MealDoc> meals = new ArrayList<>();
				for (int m = 0; m < day.meals().size(); m++) {
					var meal = day.meals().get(m);
					if (m == 0) {
						List<DietProgramDocumentRequest.IngredientDoc> ings = new ArrayList<>();
						ings.add(new DietProgramDocumentRequest.IngredientDoc(null, food1.getId(), null,
								new BigDecimal("50.00"), null, false));
						meals.add(new DietProgramDocumentRequest.MealDoc(meal.id(), ings));
					}
					else {
						meals.add(meal);
					}
				}
				days1.add(new DietProgramDocumentRequest.DayDoc(day.id(), meals));
			}
			else {
				days1.add(day);
			}
		}
		DietProgramDocumentRequest req1 = new DietProgramDocumentRequest(baseReq1.version(), "edit-q1", baseReq1.name(),
				baseReq1.goals(), days1);

		DietProgram fresh2 = loadProgram(programId2);
		DietProgramDocumentRequest baseReq2 = buildDocumentRequest(fresh2, "edit-q2");

		List<DietProgramDocumentRequest.DayDoc> days2 = new ArrayList<>();
		for (int d = 0; d < baseReq2.days().size(); d++) {
			var day = baseReq2.days().get(d);
			if (d == 0) {
				List<DietProgramDocumentRequest.MealDoc> meals = new ArrayList<>();
				for (int m = 0; m < day.meals().size(); m++) {
					var meal = day.meals().get(m);
					if (m == 0) {
						List<DietProgramDocumentRequest.IngredientDoc> ings = new ArrayList<>();
						ings.add(new DietProgramDocumentRequest.IngredientDoc(null, food1.getId(), null,
								new BigDecimal("50.00"), null, false));
						ings.add(new DietProgramDocumentRequest.IngredientDoc(null, food2.getId(), null,
								new BigDecimal("50.00"), null, false));
						ings.add(new DietProgramDocumentRequest.IngredientDoc(null, food3.getId(), null,
								new BigDecimal("50.00"), null, false));
						ings.add(new DietProgramDocumentRequest.IngredientDoc(null, food4.getId(), null,
								new BigDecimal("50.00"), null, false));
						meals.add(new DietProgramDocumentRequest.MealDoc(meal.id(), ings));
					}
					else {
						meals.add(meal);
					}
				}
				days2.add(new DietProgramDocumentRequest.DayDoc(day.id(), meals));
			}
			else {
				days2.add(day);
			}
		}
		DietProgramDocumentRequest req2 = new DietProgramDocumentRequest(baseReq2.version(), "edit-q2", baseReq2.name(),
				baseReq2.goals(), days2);

		actingAs(client);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		documentService.saveDocument(programId1, req1);
		entityManager.flush();
		entityManager.clear();
		long count1 = statistics().getPrepareStatementCount();

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		documentService.saveDocument(programId2, req2);
		entityManager.flush();
		entityManager.clear();
		long count2 = statistics().getPrepareStatementCount();

		long expectedDifference = (4 - 1) * 3;
		assertThat(count2 - count1)
			.as("Food sorgusu findAllById ile tek SQL'de çekildiğinden fark yalnız insert ve override kadardır (%d SQL); findById olsaydı fark %d olurdu",
					expectedDifference, expectedDifference + 3)
			.isEqualTo(expectedDifference);
	}

}
