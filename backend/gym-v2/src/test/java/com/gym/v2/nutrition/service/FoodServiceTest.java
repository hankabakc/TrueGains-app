package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.FoodCreateRequest;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealIngredientRepository;
import com.gym.v2.nutrition.repository.MealItemRepository;
import com.gym.v2.nutrition.repository.UserFoodOverrideRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code FoodService} görünürlük sınırı ve özel besin oluşturma testleri.
 * <p>
 * Besin arama sonuçları kullanıcıya göre filtrelenir: sporcu kendi besinlerini ve
 * <b>koçunun</b> besinlerini görür; koç kendi besinlerini ve <b>kendi sporcularının</b>
 * besinlerini görür. Bu sınır bozulursa kullanıcılar birbirlerinin özel besin listesini
 * görmeye başlar.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class FoodServiceTest {

	@Mock
	private FoodRepository foodRepository;

	@Mock
	private UserFoodOverrideRepository overrideRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private NutritionMapper nutritionMapper;

	@Mock
	private MealItemRepository mealItemRepository;

	@Mock
	private MealIngredientRepository mealIngredientRepository;

	@Mock
	private ClientRepository clientRepository;

	private FoodService service;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new FoodService(foodRepository, overrideRepository, userContextService, nutritionMapper,
				mealItemRepository, mealIngredientRepository, clientRepository, fixedClock);
	}

	private ClientEntity clientEntity(Long userId, Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setUserId(userId);
		entity.setCoachId(coachId);
		return entity;
	}

	/**
	 * {@code searchVisible} çağrısına geçirilen görünür yaratıcı kimliklerini yakalar.
	 */
	@SuppressWarnings("unchecked")
	private List<Long> capturedVisibleCreatorIds() {
		ArgumentCaptor<List<Long>> captor = ArgumentCaptor.forClass(List.class);
		verify(foodRepository).searchVisible(any(), captor.capture(), any());
		return captor.getValue();
	}

	// ---------------------------------------------------------------------------
	// Görünürlük sınırı
	// ---------------------------------------------------------------------------

	@Test
	void searchFood_clientWithCoach_seesOwnAndCoachFoodsOnly() {
		AppUser client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(client);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientEntity(1L, 2L)));
		when(foodRepository.searchVisible(any(), any(), any())).thenReturn(Collections.emptyList());

		service.searchFood("yulaf");

		// Yalnızca kendisi (1) ve koçu (2); başka hiçbir kullanıcının besini görünmemeli.
		assertThat(capturedVisibleCreatorIds()).containsExactlyInAnyOrder(1L, 2L);
	}

	@Test
	void searchFood_clientWithoutCoach_seesOnlyOwnFoods() {
		AppUser client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(client);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientEntity(1L, null)));
		when(foodRepository.searchVisible(any(), any(), any())).thenReturn(Collections.emptyList());

		service.searchFood("yulaf");

		assertThat(capturedVisibleCreatorIds()).containsExactly(1L);
	}

	@Test
	void searchFood_coach_seesOwnAndTheirClientsFoods() {
		AppUser coach = userWithId(2L, "koc@test.com", UserRole.COACH);
		when(userContextService.getCurrentUser()).thenReturn(coach);
		when(clientRepository.findAllByCoachId(2L)).thenReturn(List.of(clientEntity(10L, 2L), clientEntity(11L, 2L)));
		when(foodRepository.searchVisible(any(), any(), any())).thenReturn(Collections.emptyList());

		service.searchFood("yulaf");

		assertThat(capturedVisibleCreatorIds()).containsExactlyInAnyOrder(2L, 10L, 11L);
	}

	@Test
	void searchFood_coachWithoutClients_seesOnlyOwnFoods() {
		AppUser coach = userWithId(2L, "koc@test.com", UserRole.COACH);
		when(userContextService.getCurrentUser()).thenReturn(coach);
		when(clientRepository.findAllByCoachId(2L)).thenReturn(Collections.emptyList());
		when(foodRepository.searchVisible(any(), any(), any())).thenReturn(Collections.emptyList());

		service.searchFood("yulaf");

		assertThat(capturedVisibleCreatorIds()).containsExactly(2L);
	}

	// ---------------------------------------------------------------------------
	// Özel besin oluşturma
	// ---------------------------------------------------------------------------

	private FoodCreateRequest createRequest() {
		return new FoodCreateRequest("Yulaf", "Marka", "Tahıl", "g", new BigDecimal("100"), new BigDecimal("380"),
				new BigDecimal("13"), new BigDecimal("60"), new BigDecimal("7"), null, null, null, null, null, null,
				null, null, null);
	}

	@Test
	void createCustomFood_assignsCurrentUserAsCreatorAndMarksItNonGlobal() {
		AppUser client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(client);
		when(foodRepository.countByCreatorId(1L)).thenReturn(0L);
		when(foodRepository.save(any(Food.class))).thenAnswer(i -> i.getArgument(0));
		lenient().when(overrideRepository.findByUserIdAndFoodId(any(), any())).thenReturn(Optional.empty());

		service.createCustomFood(createRequest());

		ArgumentCaptor<Food> captor = ArgumentCaptor.forClass(Food.class);
		verify(foodRepository).save(captor.capture());
		Food saved = captor.getValue();
		// Yaratıcı istekten değil oturumdan alınmalı; aksi hâlde başkası adına besin
		// eklenebilir.
		assertThat(saved.getCreatorId()).isEqualTo(1L);
		// Kullanıcı besini asla global (herkese açık) olmamalı.
		assertThat(saved.isGlobal()).isFalse();
	}

	@Test
	void createCustomFood_whenUserReachedTheLimit_isRejectedAndNothingIsSaved() {
		AppUser client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(client);
		when(foodRepository.countByCreatorId(1L)).thenReturn(200L);

		assertThatThrownBy(() -> service.createCustomFood(createRequest())).isInstanceOf(BadRequestException.class);

		verify(foodRepository, never()).save(any());
	}

	// ---------------------------------------------------------------------------
	// Düzeltme silme — yalnızca kendi düzeltmesi
	// ---------------------------------------------------------------------------

	@Test
	void deleteOverride_looksUpOverrideScopedToCurrentUser() {
		AppUser client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(client);
		when(overrideRepository.findByUserIdAndFoodId(1L, 55L)).thenReturn(Optional.empty());

		service.deleteOverride(55L);

		// Sorgu kullanıcı kimliğiyle daraltılmalı; aksi hâlde başkasının düzeltmesi
		// silinebilir.
		verify(overrideRepository).findByUserIdAndFoodId(eq(1L), eq(55L));
		verify(overrideRepository, never()).delete(any());
	}

}
