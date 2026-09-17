package com.gym.v2.nutrition;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.nutrition.dto.FoodResponse;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.UserFoodOverride;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import com.gym.v2.nutrition.service.FoodService;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
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
 * Besin arama ve liste uçlarının sorgu maliyeti.
 * <p>
 * Her besin için kullanıcının o besne ait "değer ezmesi" (override) olup olmadığına
 * bakılır. Bu kontrol besin başına ayrı sorguyla yapılırsa arama kutusuna her harf
 * yazıldığında onlarca sorgu üretilir.
 * </p>
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class FoodSearchQueryCountIT extends IntegrationTestBase {

	@Autowired
	private FoodService foodService;

	@Autowired
	private FoodRepository foodRepository;

	@Autowired
	private UserFoodOverrideRepository overrideRepository;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	private long queryCountFor(String email, Supplier<List<?>> call) {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(email, null, List.of()));
		call.get();

		return statistics().getPrepareStatementCount();
	}

	private Food newFood(String name, AppUser creator) {
		Food food = new Food();
		food.setName(name);
		food.setCalories(new BigDecimal("100"));
		food.setProtein(new BigDecimal("10"));
		food.setCarbs(new BigDecimal("20"));
		food.setFat(new BigDecimal("5"));
		food.setDefaultUnit("g");
		food.setDefaultAmount(new BigDecimal("100"));
		food.setGlobal(false);
		food.setCreatorId(creator.getId());
		return foodRepository.saveAndFlush(food);
	}

	/** Kullanıcıya ait, aranan kelimeyi içeren {@code count} adet besin oluşturur. */
	private void seedFoods(AppUser user, int count, String keyword) {
		for (int i = 0; i < count; i++) {
			newFood(keyword + " " + i, user);
		}
	}

	@Test
	void searchFood_queryCountDoesNotGrowWithResultCount() {
		AppUser lightUser = createUser("food_light@test.com", UserRole.CLIENT);
		AppUser heavyUser = createUser("food_heavy@test.com", UserRole.CLIENT);
		seedFoods(lightUser, 1, "ayran");
		seedFoods(heavyUser, 4, "ayran");

		long lightQueries = queryCountFor(lightUser.getEmail(), () -> foodService.searchFood("ayran"));
		long heavyQueries = queryCountFor(heavyUser.getEmail(), () -> foodService.searchFood("ayran"));

		assertThat(heavyQueries)
			.as("1 sonuç %d sorgu, 4 sonuç %d sorgu ürettiyse maliyet sonuç sayısıyla büyüyor", lightQueries,
					heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getMyCustomFoods_queryCountDoesNotGrowWithFoodCount() {
		AppUser lightUser = createUser("custom_light@test.com", UserRole.CLIENT);
		AppUser heavyUser = createUser("custom_heavy@test.com", UserRole.CLIENT);
		seedFoods(lightUser, 1, "kendi");
		seedFoods(heavyUser, 4, "kendi");

		long lightQueries = queryCountFor(lightUser.getEmail(), () -> foodService.getMyCustomFoods());
		long heavyQueries = queryCountFor(heavyUser.getEmail(), () -> foodService.getMyCustomFoods());

		assertThat(heavyQueries)
			.as("1 besin %d sorgu, 4 besin %d sorgu ürettiyse maliyet veriyle büyüyor", lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void searchFood_appliesUserOverrideValues() {
		AppUser user = createUser("food_override@test.com", UserRole.CLIENT);
		Food food = newFood("mercimek", user);

		UserFoodOverride override = new UserFoodOverride();
		override.setUser(user);
		override.setFood(food);
		override.setCalories(new BigDecimal("777"));
		overrideRepository.saveAndFlush(override);

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		var results = foodService.searchFood("mercimek");

		// Sorguyu topluya çevirmek özelleştirilmiş değeri kaybetmemeli: ezmesi olan
		// besin hem özelleştirilmiş hem orijinal hâliyle listelenir.
		assertThat(results).hasSize(2);
		assertThat(results.get(0).calories()).isEqualByComparingTo("777");
		assertThat(results.get(1).calories()).isEqualByComparingTo("100");
	}

	@Test
	void searchFood_withoutOverrideReturnsOriginalValues() {
		AppUser user = createUser("food_plain@test.com", UserRole.CLIENT);
		newFood("bulgur", user);

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		var results = foodService.searchFood("bulgur");

		assertThat(results).hasSize(1);
		assertThat(results.getFirst().calories()).isEqualByComparingTo("100");
	}

	@Test
	void searchFood_capsResultCount() {
		AppUser user = createUser("limit_test@test.com", UserRole.CLIENT);
		seedFoods(user, 60, "yulaf");

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		var results = foodService.searchFood("yulaf");

		// Tavansız arama tek harflik sorguda tüm tabloyu döndürüyordu.
		assertThat(results).hasSize(50);
	}

	@Test
	void getVisibleCatalog_queryCountDoesNotGrowWithFoodCount() {
		AppUser lightUser = createUser("catalog_light@test.com", UserRole.CLIENT);
		AppUser heavyUser = createUser("catalog_heavy@test.com", UserRole.CLIENT);
		seedFoods(lightUser, 1, "katalog");
		seedFoods(heavyUser, 4, "katalog");

		long lightQueries = queryCountFor(lightUser.getEmail(), () -> foodService.getVisibleCatalog());
		long heavyQueries = queryCountFor(heavyUser.getEmail(), () -> foodService.getVisibleCatalog());

		assertThat(heavyQueries)
			.as("1 besin %d sorgu, 4 besin %d sorgu ürettiyse maliyet katalog boyuyla büyüyor", lightQueries,
					heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void getVisibleCatalog_hidesOtherUsersCustomFoods() {
		AppUser owner = createUser("catalog_owner@test.com", UserRole.CLIENT);
		AppUser stranger = createUser("catalog_stranger@test.com", UserRole.CLIENT);
		newFood("gizli tarif", owner);
		newFood("kendi tarifim", stranger);

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(stranger.getEmail(), null, List.of()));
		List<String> names = foodService.getVisibleCatalog().stream().map(FoodResponse::name).toList();

		// Başkasının özel besini (koçu değilse) telefona inmemeli (KURALLAR §1.3).
		assertThat(names).contains("kendi tarifim").doesNotContain("gizli tarif");
	}

	@Test
	void getVisibleCatalog_keepsOverriddenAndOriginalValues() {
		AppUser user = createUser("catalog_override@test.com", UserRole.CLIENT);
		Food food = newFood("nohut", user);

		UserFoodOverride override = new UserFoodOverride();
		override.setUser(user);
		override.setFood(food);
		override.setCalories(new BigDecimal("555"));
		overrideRepository.saveAndFlush(override);

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
		List<FoodResponse> nohut = foodService.getVisibleCatalog()
			.stream()
			.filter(response -> "nohut".equals(response.name()))
			.toList();

		// Katalog telefona inerken kişiye özel değer de orijinal de kaybolmamalı
		// (KURALLAR §4/5).
		assertThat(nohut).hasSize(2);
		assertThat(nohut.get(0).calories()).isEqualByComparingTo("555");
		assertThat(nohut.get(1).calories()).isEqualByComparingTo("100");
	}

}
