package com.gym.v2.nutrition;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.nutrition.dto.LogMealItemRequest;
import com.gym.v2.nutrition.dto.LogMealRequest;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.*;
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
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * G-94: Beslenme yanıtlarında besin ezmesi sorgu sayısı testleri (Test 49-52). Veri
 * büyüklüğünden bağımsız olarak yanıt başına tek ezme sorgusu yapılmasını doğrular.
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
public class NutritionOverrideQueryCountIT extends IntegrationTestBase {

	@Autowired
	private FoodRepository foodRepository;

	@Autowired
	private UserFoodOverrideRepository overrideRepository;

	@Autowired
	private DietProgramRepository programRepository;

	@Autowired
	private MealTemplateRepository templateRepository;

	@Autowired
	private RecipeRepository recipeRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void tearDown() {
		SecurityContextHolder.clearContext();
	}

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	private Food createFood(String name, BigDecimal calories) {
		Food food = new Food(name, "g", BigDecimal.valueOf(100));
		food.setCalories(calories);
		food.setProtein(new BigDecimal("10"));
		food.setCarbs(new BigDecimal("20"));
		food.setFat(new BigDecimal("5"));
		food.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		return foodRepository.saveAndFlush(food);
	}

	private UserFoodOverride createOverride(AppUser user, Food food, BigDecimal calories) {
		UserFoodOverride override = new UserFoodOverride();
		override.setUser(user);
		override.setFood(food);
		override.setCalories(calories);
		override.setProtein(new BigDecimal("10"));
		override.setCarbs(new BigDecimal("20"));
		override.setFat(new BigDecimal("5"));
		override.setCreatedAt(LocalDateTime.now());
		return overrideRepository.saveAndFlush(override);
	}

	private DietProgram createProgram(AppUser owner, String name, boolean isTemplate, List<Food> foods) {
		DietProgram program = new DietProgram(owner, name, isTemplate ? DietSource.COACH : DietSource.CLIENT);
		program.setTemplate(isTemplate);
		program.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		DietDay day = new DietDay(program, 1, "Pazartesi");
		program.getDietDays().add(day);
		Meal meal = new Meal(day, MealType.KAHVALTI, 1);
		day.getMeals().add(meal);
		for (Food food : foods) {
			MealIngredient ing = new MealIngredient(meal, food, new BigDecimal("100.00"), false);
			meal.getIngredients().add(ing);
		}
		return programRepository.saveAndFlush(program);
	}

	private MealTemplate createMealTemplate(AppUser owner, String name, List<Food> foods) {
		MealTemplate template = new MealTemplate(owner, name);
		template.setCreatedAt(LocalDateTime.now());
		template.getApplicableMealTypes().add(MealType.KAHVALTI);
		for (Food food : foods) {
			MealTemplateIngredient ing = new MealTemplateIngredient(template, food, new BigDecimal("100.00"), false);
			template.getIngredients().add(ing);
		}
		return templateRepository.saveAndFlush(template);
	}

	private Recipe createRecipe(String name, String category, List<Food> foods) {
		Recipe recipe = new Recipe(name, "Desc", "Inst", category, "http://img.jpg");
		for (Food food : foods) {
			RecipeIngredient ing = new RecipeIngredient(recipe, food, new BigDecimal("100.00"));
			recipe.getIngredients().add(ing);
		}
		return recipeRepository.saveAndFlush(recipe);
	}

	@Test
	void dietPrograms_ingredientAndProgramCount_doesNotChangeQueryCount() throws Exception {
		// (a) GET /api/v1/nutrition/diet/{id}: 1 besinli program ile 4 farklı besinli
		// program
		AppUser clientA = createUser("q49_clientA@test.com", UserRole.CLIENT);
		Food food1 = createFood("Food Q49_1", new BigDecimal("100"));
		Food food2 = createFood("Food Q49_2", new BigDecimal("100"));
		Food food3 = createFood("Food Q49_3", new BigDecimal("100"));
		Food food4 = createFood("Food Q49_4", new BigDecimal("100"));
		createOverride(clientA, food1, new BigDecimal("999"));

		DietProgram prog1 = createProgram(clientA, "Prog 1", false, List.of(food1));
		DietProgram prog4 = createProgram(clientA, "Prog 4", false, List.of(food1, food2, food3, food4));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult res1 = mockMvc
			.perform(get("/api/v1/nutrition/diet/" + prog1.getId()).header("Authorization", bearerTokenFor(clientA)))
			.andExpect(status().isOk())
			.andReturn();
		long count1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Boolean isOverridden1 = JsonPath.read(res1.getResponse().getContentAsString(),
				"$.data.dietDays[0].meals[0].ingredients[0].isOverridden");
		Number cal1 = JsonPath.read(res1.getResponse().getContentAsString(),
				"$.data.dietDays[0].meals[0].ingredients[0].calories");
		assertThat(isOverridden1).isTrue();
		assertThat(cal1.doubleValue()).isEqualTo(999.0);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult res4 = mockMvc
			.perform(get("/api/v1/nutrition/diet/" + prog4.getId()).header("Authorization", bearerTokenFor(clientA)))
			.andExpect(status().isOk())
			.andReturn();
		long count4 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Boolean isOverridden4_0 = JsonPath.read(res4.getResponse().getContentAsString(),
				"$.data.dietDays[0].meals[0].ingredients[0].isOverridden");
		Boolean isOverridden4_1 = JsonPath.read(res4.getResponse().getContentAsString(),
				"$.data.dietDays[0].meals[0].ingredients[1].isOverridden");
		assertThat(isOverridden4_0).isTrue();
		assertThat(isOverridden4_1).isFalse();

		assertThat(count4)
			.as("1 besinli ve 4 besinli programın GET /api/v1/nutrition/diet/{id} sorgu sayısı eşit olmalı (N+1 yok)")
			.isEqualTo(count1);

		// (b) GET /api/v1/nutrition/diet/my-programs: 1 programlı kullanıcı ile 3
		// programlı kullanıcı
		AppUser clientB1 = createUser("q49_clientB1@test.com", UserRole.CLIENT);
		createOverride(clientB1, food1, new BigDecimal("999"));
		createProgram(clientB1, "Prog B1_1", false, List.of(food1, food2));

		AppUser clientB3 = createUser("q49_clientB3@test.com", UserRole.CLIENT);
		createOverride(clientB3, food1, new BigDecimal("999"));
		createProgram(clientB3, "Prog B3_1", false, List.of(food1, food2));
		createProgram(clientB3, "Prog B3_2", false, List.of(food1, food2));
		createProgram(clientB3, "Prog B3_3", false, List.of(food1, food2));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/diet/my-programs").header("Authorization", bearerTokenFor(clientB1)))
			.andExpect(status().isOk());
		long countB1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/diet/my-programs").header("Authorization", bearerTokenFor(clientB3)))
			.andExpect(status().isOk());
		long countB3 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(countB3)
			.as("1 programlı ve 3 programlı kullanıcının GET /api/v1/nutrition/diet/my-programs sorgu sayısı eşit olmalı")
			.isEqualTo(countB1);

		// (c) koç olarak GET /api/v1/nutrition/diet/templates: 1 şablon ile 3 şablon
		AppUser coachC1 = createUser("q49_coachC1@test.com", UserRole.COACH);
		createOverride(coachC1, food1, new BigDecimal("999"));
		createProgram(coachC1, "Tmpl C1_1", true, List.of(food1, food2));

		AppUser coachC3 = createUser("q49_coachC3@test.com", UserRole.COACH);
		createOverride(coachC3, food1, new BigDecimal("999"));
		createProgram(coachC3, "Tmpl C3_1", true, List.of(food1, food2));
		createProgram(coachC3, "Tmpl C3_2", true, List.of(food1, food2));
		createProgram(coachC3, "Tmpl C3_3", true, List.of(food1, food2));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/diet/templates").header("Authorization", bearerTokenFor(coachC1)))
			.andExpect(status().isOk());
		long countC1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/diet/templates").header("Authorization", bearerTokenFor(coachC3)))
			.andExpect(status().isOk());
		long countC3 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(countC3)
			.as("1 şablonlu ve 3 şablonlu koçun GET /api/v1/nutrition/diet/templates sorgu sayısı eşit olmalı")
			.isEqualTo(countC1);
	}

	@Test
	void templates_ingredientAndTemplateCount_doesNotChangeQueryCount() throws Exception {
		AppUser userA = createUser("q50_userA@test.com", UserRole.CLIENT);
		AppUser userB = createUser("q50_userB@test.com", UserRole.CLIENT);
		Food food1 = createFood("Food Q50_1", new BigDecimal("100"));
		Food food2 = createFood("Food Q50_2", new BigDecimal("100"));
		Food food3 = createFood("Food Q50_3", new BigDecimal("100"));
		Food food4 = createFood("Food Q50_4", new BigDecimal("100"));
		createOverride(userA, food1, new BigDecimal("999"));
		createOverride(userB, food1, new BigDecimal("999"));

		createMealTemplate(userA, "Tmpl A", List.of(food1));

		createMealTemplate(userB, "Tmpl B1", List.of(food1, food2, food3));
		createMealTemplate(userB, "Tmpl B2", List.of(food1, food2, food3));
		createMealTemplate(userB, "Tmpl B3", List.of(food1, food2, food3));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult resListA = mockMvc
			.perform(get("/api/v1/nutrition/templates").header("Authorization", bearerTokenFor(userA)))
			.andExpect(status().isOk())
			.andReturn();
		long countListA = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Boolean isOverriddenA = JsonPath.read(resListA.getResponse().getContentAsString(),
				"$.data[0].ingredients[0].isOverridden");
		Number calA = JsonPath.read(resListA.getResponse().getContentAsString(), "$.data[0].ingredients[0].calories");
		assertThat(isOverriddenA).isTrue();
		assertThat(calA.doubleValue()).isEqualTo(999.0);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/templates").header("Authorization", bearerTokenFor(userB)))
			.andExpect(status().isOk());
		long countListB = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(countListB)
			.as("GET /api/v1/nutrition/templates: 1 şablon ve 3 şablon listesi sorgu sayısı eşit olmalı")
			.isEqualTo(countListA);

		// Detail: 1 vs 4 ingredients for userA
		MealTemplate tmplDetail1 = createMealTemplate(userA, "Detail 1", List.of(food1));
		MealTemplate tmplDetail4 = createMealTemplate(userA, "Detail 4", List.of(food1, food2, food3, food4));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult resDetail1 = mockMvc.perform(get("/api/v1/nutrition/templates/" + tmplDetail1.getId())
			.header("Authorization", bearerTokenFor(userA))).andExpect(status().isOk()).andReturn();
		long countDetail1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Boolean isOverriddenDet1 = JsonPath.read(resDetail1.getResponse().getContentAsString(),
				"$.data.ingredients[0].isOverridden");
		Number calDet1 = JsonPath.read(resDetail1.getResponse().getContentAsString(), "$.data.ingredients[0].calories");
		assertThat(isOverriddenDet1).isTrue();
		assertThat(calDet1.doubleValue()).isEqualTo(999.0);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/templates/" + tmplDetail4.getId()).header("Authorization",
				bearerTokenFor(userA)))
			.andExpect(status().isOk());
		long countDetail4 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(countDetail4)
			.as("GET /api/v1/nutrition/templates/{id}: 1 malzeme ve 4 malzeme detay sorgu sayısı eşit olmalı")
			.isEqualTo(countDetail1);
	}

	@Test
	void recipesByCategory_recipeCount_doesNotChangeQueryCount() throws Exception {
		AppUser user = createUser("q51_user@test.com", UserRole.CLIENT);
		Food food1 = createFood("Food Q51_1", new BigDecimal("100"));
		Food food2 = createFood("Food Q51_2", new BigDecimal("100"));
		createOverride(user, food1, new BigDecimal("999"));

		createRecipe("Rec Q1_1", "Q1", List.of(food1, food2));

		createRecipe("Rec Q3_1", "Q3", List.of(food1, food2));
		createRecipe("Rec Q3_2", "Q3", List.of(food1, food2));
		createRecipe("Rec Q3_3", "Q3", List.of(food1, food2));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult res1 = mockMvc
			.perform(get("/api/v1/nutrition/recipes/category/Q1").header("Authorization", bearerTokenFor(user)))
			.andExpect(status().isOk())
			.andReturn();
		long count1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Number cal1 = JsonPath.read(res1.getResponse().getContentAsString(), "$.data[0].ingredients[0].calories");
		assertThat(cal1.doubleValue()).isEqualTo(999.0);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc.perform(get("/api/v1/nutrition/recipes/category/Q3").header("Authorization", bearerTokenFor(user)))
			.andExpect(status().isOk());
		long count3 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(count3)
			.as("GET /api/v1/nutrition/recipes/category/{c}: 1 tarif ve 3 tarif kategorisi sorgu sayısı eşit olmalı")
			.isEqualTo(count1);
	}

	@Test
	void logMeal_itemCount_doesNotChangeQueryCount() throws Exception {
		AppUser user = createUser("q52_user@test.com", UserRole.CLIENT);
		Food food1 = createFood("Food Q52_1", new BigDecimal("100"));
		Food food2 = createFood("Food Q52_2", new BigDecimal("100"));
		Food food3 = createFood("Food Q52_3", new BigDecimal("100"));
		Food food4 = createFood("Food Q52_4", new BigDecimal("100"));
		createOverride(user, food1, new BigDecimal("999"));

		LogMealRequest req1 = new LogMealRequest(MealType.KAHVALTI, Instant.parse("2026-01-01T08:00:00Z"),
				List.of(new LogMealItemRequest(food1.getId(), null, new BigDecimal("100.00"), "not1", null, null)));

		LogMealRequest req4 = new LogMealRequest(MealType.OGLE_YEMEGI, Instant.parse("2026-01-01T12:00:00Z"),
				List.of(new LogMealItemRequest(food1.getId(), null, new BigDecimal("100.00"), "not1", null, null),
						new LogMealItemRequest(food1.getId(), null, new BigDecimal("100.00"), "not2", null, null),
						new LogMealItemRequest(food1.getId(), null, new BigDecimal("100.00"), "not3", null, null),
						new LogMealItemRequest(food1.getId(), null, new BigDecimal("100.00"), "not4", null, null)));

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		MvcResult res1 = mockMvc
			.perform(post("/api/v1/nutrition/meal-logs/log").header("Authorization", bearerTokenFor(user))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req1)))
			.andExpect(status().isOk())
			.andReturn();
		long count1 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		Number cal1 = JsonPath.read(res1.getResponse().getContentAsString(), "$.data.items[0].calories");
		assertThat(cal1.doubleValue()).isEqualTo(999.0);

		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		mockMvc
			.perform(post("/api/v1/nutrition/meal-logs/log").header("Authorization", bearerTokenFor(user))
				.contentType(MediaType.APPLICATION_JSON)
				.content(objectMapper.writeValueAsString(req4)))
			.andExpect(status().isOk());
		long count4 = statistics().getPrepareStatementCount() - statistics().getEntityInsertCount();

		assertThat(count4).as("POST /api/v1/nutrition/meal-logs/log: 1 malzeme ve 4 malzeme sorgu sayısı eşit olmalı")
			.isEqualTo(count1);
	}

}
