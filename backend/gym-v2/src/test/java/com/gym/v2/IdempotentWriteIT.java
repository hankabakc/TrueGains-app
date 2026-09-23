package com.gym.v2;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.measurement.dto.MeasurementDTO;
import com.gym.v2.measurement.entity.Measurement;
import com.gym.v2.measurement.repository.MeasurementRepository;
import com.gym.v2.measurement.service.MeasurementService;
import com.gym.v2.nutrition.dto.LogMealItemRequest;
import com.gym.v2.nutrition.dto.LogMealRequest;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.MealItem;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.entity.WaterIntake;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealEntryRepository;
import com.gym.v2.nutrition.repository.WaterIntakeRepository;
import com.gym.v2.nutrition.service.MealLogService;
import com.gym.v2.nutrition.service.WaterIntakeService;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.repository.MessageRepository;
import com.gym.v2.social.service.ChatService;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.dto.WorkoutSessionRequestDTO;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.service.WorkoutSessionService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Tekrar koruması (G-79): servis, test şeması (entity eşlemesi) ve benzersizlik kısıtı
 * birlikte sınanır.
 */
class IdempotentWriteIT extends IntegrationTestBase {

	@Autowired
	private WorkoutSessionService workoutSessionService;

	@Autowired
	private WorkoutSessionRepository workoutSessionRepository;

	@Autowired
	private ChatService chatService;

	@Autowired
	private MessageRepository messageRepository;

	@Autowired
	private MealLogService mealLogService;

	@Autowired
	private MealEntryRepository mealEntryRepository;

	@Autowired
	private FoodRepository foodRepository;

	@Autowired
	private WaterIntakeService waterIntakeService;

	@Autowired
	private WaterIntakeRepository waterIntakeRepository;

	@Autowired
	private MeasurementService measurementService;

	@Autowired
	private MeasurementRepository measurementRepository;

	@Autowired
	private TrainingBlockRepository trainingBlockRepository;

	@Autowired
	private Clock clock;

	@PersistenceContext
	private EntityManager entityManager;

	private void actingAs(AppUser user) {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
	}

	private static final Instant MEAL_TIME = Instant.parse("2026-09-17T08:00:00Z");

	private Food savedFood() {
		Food food = new Food();
		food.setName("yulaf");
		food.setCalories(new BigDecimal("100"));
		food.setProtein(new BigDecimal("10"));
		food.setCarbs(new BigDecimal("20"));
		food.setFat(new BigDecimal("5"));
		food.setDefaultUnit("g");
		food.setDefaultAmount(new BigDecimal("100"));
		food.setGlobal(true);
		return foodRepository.saveAndFlush(food);
	}

	private List<MealEntry> mealsOf(AppUser user) {
		return mealEntryRepository.findDailyLogs(user.getId(), MEAL_TIME.minusSeconds(3600),
				MEAL_TIME.plusSeconds(3600));
	}

	@AfterEach
	void tearDown() {
		SecurityContextHolder.clearContext();
	}

	@Test
	void workoutSession_sameLocalIdTwice_isStoredOnce() {
		AppUser client = createUser("idem_ws@test.com", UserRole.CLIENT);
		actingAs(client);

		WorkoutSessionRequestDTO request = new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null,
				"yerel-ws-1");
		workoutSessionService.logWorkoutSession(request);
		entityManager.flush();
		entityManager.clear();

		workoutSessionService.logWorkoutSession(request);
		entityManager.flush();
		entityManager.clear();

		assertThat(workoutSessionRepository.findHistoryWithLogs(client.getId())).hasSize(1);
	}

	@Test
	void message_sameLocalIdTwice_isStoredOnce() {
		AppUser coach = createUser("idem_coach@test.com", UserRole.COACH);
		AppUser client = createUser("idem_client@test.com", UserRole.CLIENT);

		ClientEntity clientProfile = new ClientEntity();
		clientProfile.setUser(client);
		clientProfile.setFullName("Sporcu");
		clientProfile.setCoachId(coach.getId());
		clientRepository.saveAndFlush(clientProfile);

		actingAs(client);
		ConversationDTO conversation = chatService.initiateConversation(coach.getId());

		SendMessageRequest request = new SendMessageRequest(conversation.id(), "tek mesaj", null, null, "yerel-msg-1");
		chatService.sendMessage(request);
		entityManager.flush();
		entityManager.clear();

		chatService.sendMessage(request);
		entityManager.flush();
		entityManager.clear();

		assertThat(messageRepository.findVisibleMessages(conversation.id(), client.getId(), PageRequest.of(0, 10))
			.getTotalElements()).isEqualTo(1);
	}

	@Test
	void sameLocalId_differentUsers_bothStored() {
		AppUser a = createUser("idem_a@test.com", UserRole.CLIENT);
		AppUser b = createUser("idem_b@test.com", UserRole.CLIENT);

		actingAs(a);
		workoutSessionService
			.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null, "ortak-kimlik"));
		entityManager.flush();

		actingAs(b);
		workoutSessionService
			.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null, "ortak-kimlik"));
		entityManager.flush();
		entityManager.clear();

		assertThat(workoutSessionRepository.findHistoryWithLogs(a.getId())).hasSize(1);
		assertThat(workoutSessionRepository.findHistoryWithLogs(b.getId())).hasSize(1);
	}

	@Test
	void database_rejectsDuplicateLocalIdForSameUser() {
		AppUser client = createUser("idem_db@test.com", UserRole.CLIENT);

		WorkoutSession s1 = new WorkoutSession(client, "Gun 1", 60);
		s1.setLocalId("yerel-db");
		s1.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		workoutSessionRepository.saveAndFlush(s1);

		WorkoutSession s2 = new WorkoutSession(client, "Gun 1", 60);
		s2.setLocalId("yerel-db");
		s2.onPersist(Instant.parse("2026-01-01T00:00:00Z"));

		assertThatThrownBy(() -> workoutSessionRepository.saveAndFlush(s2))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

	@Test
	void mealLog_sameItemLocalIdTwice_isStoredOnce() {
		AppUser client = createUser("idem_meal@test.com", UserRole.CLIENT);
		Food food = savedFood();
		actingAs(client);

		LogMealRequest request = new LogMealRequest(MealType.KAHVALTI, MEAL_TIME,
				List.of(new LogMealItemRequest(food.getId(), null, new BigDecimal("50"), null, "yerel-meal-1", null)));
		mealLogService.logMealEntry(request);
		entityManager.flush();
		entityManager.clear();

		mealLogService.logMealEntry(request);
		entityManager.flush();
		entityManager.clear();

		assertThat(mealsOf(client)).hasSize(1);
		assertThat(mealsOf(client).getFirst().getItems()).hasSize(1);
	}

	@Test
	void mealLog_newLocalIdSameMeal_isAddedToSameEntry() {
		AppUser client = createUser("idem_meal_merge@test.com", UserRole.CLIENT);
		Food food = savedFood();
		actingAs(client);

		mealLogService.logMealEntry(new LogMealRequest(MealType.KAHVALTI, MEAL_TIME,
				List.of(new LogMealItemRequest(food.getId(), null, new BigDecimal("50"), null, "yerel-meal-a", null))));
		entityManager.flush();
		entityManager.clear();

		mealLogService.logMealEntry(new LogMealRequest(MealType.KAHVALTI, MEAL_TIME,
				List.of(new LogMealItemRequest(food.getId(), null, new BigDecimal("80"), null, "yerel-meal-b", null))));
		entityManager.flush();
		entityManager.clear();

		// Tekrar koruması yeni kalemi yutmamalı: aynı öğüne ikinci besin eklenir
		// (KURALLAR §4/5).
		assertThat(mealsOf(client)).hasSize(1);
		assertThat(mealsOf(client).getFirst().getItems()).extracting(MealItem::getLocalId)
			.containsExactlyInAnyOrder("yerel-meal-a", "yerel-meal-b");
	}

	@Test
	void database_rejectsDuplicateMealItemLocalIdInSameEntry() {
		AppUser client = createUser("idem_meal_db@test.com", UserRole.CLIENT);
		Food food = savedFood();
		actingAs(client);
		mealLogService.logMealEntry(new LogMealRequest(MealType.KAHVALTI, MEAL_TIME, List
			.of(new LogMealItemRequest(food.getId(), null, new BigDecimal("50"), null, "yerel-meal-db", null))));
		entityManager.flush();
		MealEntry entry = mealsOf(client).getFirst();

		MealItem duplicate = new MealItem();
		duplicate.setMealEntry(entry);
		duplicate.setFood(food);
		duplicate.setAmount(new BigDecimal("50"));
		duplicate.setLocalId("yerel-meal-db");
		entry.addItem(duplicate);

		assertThatThrownBy(() -> mealEntryRepository.saveAndFlush(entry))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

	// --- G-86: internetsiz su ve ölçüm — tekrar koruması ve kaydın kendi günü/anı ---

	private AppUser clientWithProfile(String email) {
		AppUser client = createUser(email, UserRole.CLIENT);
		ClientEntity profile = new ClientEntity();
		profile.setUser(client);
		profile.setFullName("Sporcu");
		clientRepository.saveAndFlush(profile);
		return client;
	}

	@Test
	void water_queuedRequestTwice_isStoredOnceOnItsOwnDay() throws Exception {
		AppUser client = createUser("idem_water@test.com", UserRole.CLIENT);
		LocalDate yesterday = LocalDate.now(clock).minusDays(1);

		// Kuyruk isteği uygulamanın gönderdiği biçimde:
		// /nutrition/water?amountMl=…&localId=…&intakeDate=…
		for (int i = 0; i < 2; i++) {
			mockMvc
				.perform(post("/api/v1/nutrition/water").header("Authorization", bearerTokenFor(client))
					.param("amountMl", "250")
					.param("localId", "yerel-su-1")
					.param("intakeDate", yesterday.toString()))
				.andExpect(status().isOk());
		}
		entityManager.flush();
		entityManager.clear();

		assertThat(waterIntakeRepository.findByUserIdAndIntakeDate(client.getId(), yesterday))
			.extracting(WaterIntake::getLocalId)
			.containsExactly("yerel-su-1");
	}

	@Test
	void water_withoutIntakeDate_isStoredOnToday() {
		AppUser client = createUser("water_today@test.com", UserRole.CLIENT);
		actingAs(client);

		waterIntakeService.addWater(300, null, null);
		entityManager.flush();
		entityManager.clear();

		assertThat(waterIntakeRepository.findByUserIdAndIntakeDate(client.getId(), LocalDate.now(clock))).hasSize(1);
	}

	@Test
	void water_futureIntakeDate_isRejectedAndNothingStored() throws Exception {
		AppUser client = createUser("water_future@test.com", UserRole.CLIENT);
		LocalDate tomorrow = LocalDate.now(clock).plusDays(1);

		mockMvc
			.perform(post("/api/v1/nutrition/water").header("Authorization", bearerTokenFor(client))
				.param("amountMl", "250")
				.param("intakeDate", tomorrow.toString()))
			.andExpect(status().isBadRequest());

		assertThat(waterIntakeRepository.findByUserIdAndIntakeDate(client.getId(), tomorrow)).isEmpty();
	}

	@Test
	void water_nonPositiveAmount_isRejectedAndNothingStored() throws Exception {
		AppUser client = createUser("water_negative@test.com", UserRole.CLIENT);

		mockMvc
			.perform(post("/api/v1/nutrition/water").header("Authorization", bearerTokenFor(client))
				.param("amountMl", "-500"))
			.andExpect(status().isBadRequest());

		assertThat(waterIntakeRepository.findByUserIdAndIntakeDate(client.getId(), LocalDate.now(clock))).isEmpty();
	}

	@Test
	void database_rejectsDuplicateWaterLocalIdForSameUser() {
		AppUser client = createUser("water_db@test.com", UserRole.CLIENT);
		WaterIntake first = new WaterIntake(client, 250, LocalDate.of(2026, 9, 17));
		first.setLocalId("yerel-su-db");
		waterIntakeRepository.saveAndFlush(first);

		WaterIntake second = new WaterIntake(client, 250, LocalDate.of(2026, 9, 17));
		second.setLocalId("yerel-su-db");

		assertThatThrownBy(() -> waterIntakeRepository.saveAndFlush(second))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

	@Test
	void measurement_queuedRequestTwice_isStoredOnceWithItsOwnTime() throws Exception {
		AppUser client = clientWithProfile("idem_measure@test.com");
		Instant measuredAt = Instant.parse("2026-09-17T06:30:00Z");
		String body = objectMapper
			.writeValueAsString(Map.of("weight", 72.5, "createdAt", measuredAt.toString(), "localId", "yerel-olcum-1"));

		for (int i = 0; i < 2; i++) {
			mockMvc
				.perform(post("/api/v1/measurements").header("Authorization", bearerTokenFor(client))
					.contentType(MediaType.APPLICATION_JSON)
					.content(body))
				.andExpect(status().isOk());
		}
		entityManager.flush();
		entityManager.clear();

		List<Measurement> saved = measurementRepository
			.findByUser_ExternalIdOrderByCreatedAtDesc(client.getExternalId(), PageRequest.of(0, 10))
			.getContent();
		assertThat(saved).extracting(Measurement::getLocalId).containsExactly("yerel-olcum-1");
		assertThat(saved.getFirst().getCreatedAt()).isEqualTo(measuredAt);
	}

	@Test
	void measurement_withoutCreatedAt_isStampedByClock() {
		AppUser client = clientWithProfile("measure_clock@test.com");
		actingAs(client);
		MeasurementDTO request = new MeasurementDTO(null, new BigDecimal("72.5"), null, null, null, null, null, null,
				null, null, null, null, null, null, null, null, null);

		Instant before = clock.instant();
		MeasurementDTO saved = measurementService.addMeasurement(request);
		Instant after = clock.instant();

		assertThat(saved.createdAt()).isBetween(before, after);
	}

	@Test
	void database_rejectsDuplicateMeasurementLocalIdForSameUser() {
		AppUser client = createUser("measure_db@test.com", UserRole.CLIENT);
		Measurement first = new Measurement();
		first.setUser(client);
		first.setCreatedAt(Instant.parse("2026-09-17T06:30:00Z"));
		first.setLocalId("yerel-olcum-db");
		measurementRepository.saveAndFlush(first);

		Measurement second = new Measurement();
		second.setUser(client);
		second.setCreatedAt(Instant.parse("2026-09-17T06:30:00Z"));
		second.setLocalId("yerel-olcum-db");

		assertThatThrownBy(() -> measurementRepository.saveAndFlush(second))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

	// --- G-87: internetsiz özel besin — tekrar koruması ve öğünün besine cihaz
	// kimliğiyle bağlanması ---

	private String customFoodJson(String localId) throws Exception {
		return objectMapper.writeValueAsString(Map.of("name", "Ev yoğurdu", "defaultUnit", "g", "defaultAmount", 100,
				"calories", 60, "protein", 4, "carbs", 5, "fat", 3, "localId", localId));
	}

	private String mealWithQueuedFoodJson(String foodLocalId) throws Exception {
		return objectMapper.writeValueAsString(Map.of("mealType", "KAHVALTI", "takenDatetime", MEAL_TIME.toString(),
				"items", List.of(Map.of("amount", 150, "localId", "yerel-kalem-1", "foodLocalId", foodLocalId))));
	}

	@Test
	void customFood_queuedRequestTwice_isStoredOnce() throws Exception {
		AppUser client = createUser("idem_food@test.com", UserRole.CLIENT);

		for (int i = 0; i < 2; i++) {
			mockMvc
				.perform(post("/api/v1/nutrition/foods").header("Authorization", bearerTokenFor(client))
					.contentType(MediaType.APPLICATION_JSON)
					.content(customFoodJson("yerel-besin-1")))
				.andExpect(status().isOk());
		}
		entityManager.flush();
		entityManager.clear();

		assertThat(foodRepository.findByCreatorIdOrderByCreatedAtDesc(client.getId())).extracting(Food::getLocalId)
			.containsExactly("yerel-besin-1");
	}

	@Test
	void mealLog_itemByFoodLocalId_isLinkedToOwnQueuedFood() throws Exception {
		AppUser client = createUser("food_link@test.com", UserRole.CLIENT);
		// Kuyruk sırası (K2-08): önce besin, sonra ona cihaz kimliğiyle bağlanan öğün.
		mockMvc
			.perform(post("/api/v1/nutrition/foods").header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(customFoodJson("yerel-besin-2")))
			.andExpect(status().isOk());

		mockMvc
			.perform(post("/api/v1/nutrition/meal-logs/log").header("Authorization", bearerTokenFor(client))
				.contentType(MediaType.APPLICATION_JSON)
				.content(mealWithQueuedFoodJson("yerel-besin-2")))
			.andExpect(status().isOk());
		entityManager.flush();
		entityManager.clear();

		Food food = foodRepository.findByCreatorIdAndLocalId(client.getId(), "yerel-besin-2").orElseThrow();
		MealItem item = mealsOf(client).getFirst().getItems().getFirst();
		assertThat(item.getFood().getId()).isEqualTo(food.getId());
		assertThat(item.getLocalId()).isEqualTo("yerel-kalem-1");
	}

	@Test
	void mealLog_foodLocalIdOfAnotherUser_isNotFoundAndNothingStored() throws Exception {
		AppUser owner = createUser("food_owner@test.com", UserRole.CLIENT);
		AppUser other = createUser("food_other@test.com", UserRole.CLIENT);
		mockMvc
			.perform(post("/api/v1/nutrition/foods").header("Authorization", bearerTokenFor(owner))
				.contentType(MediaType.APPLICATION_JSON)
				.content(customFoodJson("baskasinin-besini")))
			.andExpect(status().isOk());

		mockMvc
			.perform(post("/api/v1/nutrition/meal-logs/log").header("Authorization", bearerTokenFor(other))
				.contentType(MediaType.APPLICATION_JSON)
				.content(mealWithQueuedFoodJson("baskasinin-besini")))
			.andExpect(status().isNotFound());
		entityManager.flush();
		entityManager.clear();

		assertThat(mealsOf(other).stream().flatMap(entry -> entry.getItems().stream()).toList()).isEmpty();
	}

	@Test
	void database_rejectsDuplicateFoodLocalIdForSameCreator() {
		AppUser client = createUser("food_db@test.com", UserRole.CLIENT);
		Food first = savedFood();
		first.setGlobal(false);
		first.setCreatorId(client.getId());
		first.setLocalId("yerel-besin-db");
		foodRepository.saveAndFlush(first);

		Food second = new Food();
		second.setName("kopya");
		second.setDefaultUnit("g");
		second.setDefaultAmount(new BigDecimal("100"));
		second.setGlobal(false);
		second.setCreatorId(client.getId());
		second.setLocalId("yerel-besin-db");

		assertThatThrownBy(() -> foodRepository.saveAndFlush(second))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

	// --- G-74: internetsiz oluşturulan kişisel program ---

	private String personalProgramJson(String localId) throws Exception {
		return objectMapper.writeValueAsString(Map.of("name", "Yerel Program", "start_date", "2026-09-23",
				"duration_weeks", 4, "workout_days", List.of(), "local_id", localId));
	}

	@Test
	void personalProgram_queuedCreateTwice_isStoredOnce() throws Exception {
		AppUser client = createUser("idem_prog@test.com", UserRole.CLIENT);

		for (int i = 0; i < 2; i++) {
			mockMvc
				.perform(post("/api/v1/training/programs/personal").header("Authorization", bearerTokenFor(client))
					.contentType(MediaType.APPLICATION_JSON)
					.content(personalProgramJson("yerel-program-1")))
				.andExpect(status().isOk());
		}
		entityManager.flush();
		entityManager.clear();

		assertThat(trainingBlockRepository.findByClientId(client.getId())).extracting(TrainingBlock::getLocalId)
			.containsExactly("yerel-program-1");
	}

	@Test
	void personalProgram_localIdOfAnotherClient_createsOwnProgram() throws Exception {
		AppUser owner = createUser("prog_owner@test.com", UserRole.CLIENT);
		AppUser other = createUser("prog_other@test.com", UserRole.CLIENT);

		for (AppUser user : List.of(owner, other)) {
			mockMvc
				.perform(post("/api/v1/training/programs/personal").header("Authorization", bearerTokenFor(user))
					.contentType(MediaType.APPLICATION_JSON)
					.content(personalProgramJson("ayni-kimlik")))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.data.client_id").value(user.getId()));
		}
		entityManager.flush();
		entityManager.clear();

		assertThat(trainingBlockRepository.findByClientId(owner.getId())).hasSize(1);
		assertThat(trainingBlockRepository.findByClientId(other.getId())).hasSize(1);
	}

	@Test
	void database_rejectsDuplicateProgramLocalIdForSameClient() {
		AppUser client = createUser("prog_db@test.com", UserRole.CLIENT);
		TrainingBlock first = new TrainingBlock("A", null, null, client, LocalDate.of(2026, 9, 23),
				LocalDate.of(2026, 10, 21));
		first.setLocalId("yerel-program-db");
		trainingBlockRepository.saveAndFlush(first);

		TrainingBlock second = new TrainingBlock("B", null, null, client, LocalDate.of(2026, 9, 23),
				LocalDate.of(2026, 10, 21));
		second.setLocalId("yerel-program-db");

		assertThatThrownBy(() -> trainingBlockRepository.saveAndFlush(second))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

}
