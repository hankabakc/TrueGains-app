package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.LogMealItemRequest;
import com.gym.v2.nutrition.dto.MealEntryResponse;
import com.gym.v2.nutrition.dto.LogMealRequest;
import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.MealItem;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.repository.FoodRepository;
import com.gym.v2.nutrition.repository.MealEntryRepository;
import com.gym.v2.nutrition.repository.MealItemRepository;
import com.gym.v2.nutrition.repository.RecipeRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code MealLogService} birim testleri.
 * <p>
 * Bu servis kullanıcının öğün kaydını tutar ve günlük toplamı tetikler. Buradaki bir hata
 * ya veri kaybına (girilen öğün kaydolmaz) ya da yanlış günlük toplama yol açar.
 * {@code NutrientCalculator} ayrıca test edildi; burada <b>onu çağıran katmanın</b>
 * doğruluğu doğrulanır.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class MealLogServiceTest {

	@Mock
	private MealEntryRepository mealEntryRepository;

	@Mock
	private MealItemRepository mealItemRepository;

	@Mock
	private FoodRepository foodRepository;

	@Mock
	private RecipeRepository recipeRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private NutritionMapper nutritionMapper;

	@Mock
	private NutrientCalculator nutrientCalculator;

	private static final Instant NOW = Instant.parse("2026-01-01T12:00:00Z");

	private MealLogService service;

	private AppUser currentUser;

	private AppUser otherUser;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(NOW, ZoneOffset.UTC);
		service = new MealLogService(mealEntryRepository, mealItemRepository, foodRepository, recipeRepository,
				userContextService, nutritionMapper, nutrientCalculator, fixedClock);

		currentUser = userWithId(1L, "client@test.com");
		otherUser = userWithId(2L, "baskasi@test.com");
		lenient().when(userContextService.getCurrentUser()).thenReturn(currentUser);
		lenient().when(mealEntryRepository.saveAndFlush(any(MealEntry.class))).thenAnswer(i -> i.getArgument(0));
		lenient().when(mealEntryRepository.save(any(MealEntry.class))).thenAnswer(i -> i.getArgument(0));
	}

	private Food food(Long id) {
		Food f = new Food();
		f.setId(id);
		f.setName("Yulaf");
		f.setDefaultAmount(new BigDecimal("100"));
		return f;
	}

	// ---------------------------------------------------------------------------
	// logMealEntry — kayıt birleştirme ve geçersiz kalem elemesi
	// ---------------------------------------------------------------------------

	@Test
	void logMealEntry_existingEntryForSameMealType_mergesInsteadOfCreatingSecondEntry() {
		MealEntry existing = new MealEntry(currentUser, NOW, MealType.KAHVALTI);
		when(mealEntryRepository.findByClientAndMealTypeAndDateRange(any(), any(), any(), any()))
			.thenReturn(Optional.of(existing));
		when(foodRepository.findById(10L)).thenReturn(Optional.of(food(10L)));

		service.logMealEntry(new LogMealRequest(MealType.KAHVALTI, NOW,
				List.of(new LogMealItemRequest(10L, null, new BigDecimal("50"), null, null))));

		// Aynı öğün için ikinci bir kayıt AÇILMAMALI (aksi hâlde gün içinde çift
		// kahvaltı).
		verify(mealEntryRepository, never()).save(any(MealEntry.class));
		assertThat(existing.getItems()).hasSize(1);
	}

	@Test
	void logMealEntry_noExistingEntry_createsNewOne() {
		when(mealEntryRepository.findByClientAndMealTypeAndDateRange(any(), any(), any(), any()))
			.thenReturn(Optional.empty());

		service.logMealEntry(new LogMealRequest(MealType.AKSAM_YEMEGI, NOW, List.of()));

		verify(mealEntryRepository).save(any(MealEntry.class));
	}

	@Test
	void logMealEntry_itemsWithNullOrNonPositiveAmount_areSkipped() {
		MealEntry existing = new MealEntry(currentUser, NOW, MealType.OGLE_YEMEGI);
		when(mealEntryRepository.findByClientAndMealTypeAndDateRange(any(), any(), any(), any()))
			.thenReturn(Optional.of(existing));

		service.logMealEntry(new LogMealRequest(MealType.OGLE_YEMEGI, NOW,
				List.of(new LogMealItemRequest(10L, null, null, null, null),
						new LogMealItemRequest(10L, null, BigDecimal.ZERO, null, null),
						new LogMealItemRequest(10L, null, new BigDecimal("-5"), null, null))));

		// Üç kalem de elenmeli; besin bile sorgulanmamalı.
		assertThat(existing.getItems()).isEmpty();
		verify(foodRepository, never()).findById(any());
	}

	@Test
	void logMealEntry_unknownFoodId_throwsNotFound() {
		MealEntry existing = new MealEntry(currentUser, NOW, MealType.OTHER);
		when(mealEntryRepository.findByClientAndMealTypeAndDateRange(any(), any(), any(), any()))
			.thenReturn(Optional.of(existing));
		when(foodRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.logMealEntry(new LogMealRequest(MealType.OTHER, NOW,
				List.of(new LogMealItemRequest(404L, null, new BigDecimal("100"), null, null)))))
			.isInstanceOf(NotFoundException.class);
	}

	@Test
	void logMealEntry_afterAddingItems_recalculatesEntryTotals() {
		MealEntry existing = new MealEntry(currentUser, NOW, MealType.KAHVALTI);
		when(mealEntryRepository.findByClientAndMealTypeAndDateRange(any(), any(), any(), any()))
			.thenReturn(Optional.of(existing));
		when(foodRepository.findById(10L)).thenReturn(Optional.of(food(10L)));

		service.logMealEntry(new LogMealRequest(MealType.KAHVALTI, NOW,
				List.of(new LogMealItemRequest(10L, null, new BigDecimal("50"), null, null))));

		// Toplam yeniden hesaplanmazsa kullanıcı eski/yanlış günlük değeri görür.
		verify(nutrientCalculator).calculateMealEntryTotals(existing);
	}

	// ---------------------------------------------------------------------------
	// addFoodToMealLog — bugünün aynı öğününe ekleme
	// ---------------------------------------------------------------------------

	@Test
	void addFoodToMealLog_entryOfSameMealTypeExistsToday_reusesItInsteadOfCreatingNew() {
		MealEntry kahvalti = new MealEntry(currentUser, NOW, MealType.KAHVALTI);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(kahvalti));
		when(foodRepository.findById(10L)).thenReturn(Optional.of(food(10L)));

		service.addFoodToMealLog(MealType.KAHVALTI, 10L, new BigDecimal("30"), false);

		verify(mealEntryRepository, never()).save(any(MealEntry.class));
		assertThat(kahvalti.getItems()).hasSize(1);
	}

	@Test
	void addFoodToMealLog_onlyDifferentMealTypeExistsToday_createsSeparateEntry() {
		MealEntry ogle = new MealEntry(currentUser, NOW, MealType.OGLE_YEMEGI);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(ogle));
		when(foodRepository.findById(10L)).thenReturn(Optional.of(food(10L)));

		service.addFoodToMealLog(MealType.AKSAM_YEMEGI, 10L, new BigDecimal("30"), false);

		// Akşam yemeği öğle yemeğine yazılmamalı.
		verify(mealEntryRepository).save(any(MealEntry.class));
		assertThat(ogle.getItems()).isEmpty();
	}

	// ---------------------------------------------------------------------------
	// Silme yolları — sahiplik (IDOR) kontrolü ve boş kayıt temizliği
	// ---------------------------------------------------------------------------

	@Test
	void deleteMealEntry_entryBelongsToAnotherUser_throwsAndDoesNotDelete() {
		MealEntry foreign = new MealEntry(otherUser, NOW, MealType.OGLE_YEMEGI);
		when(mealEntryRepository.findById(99L)).thenReturn(Optional.of(foreign));

		assertThatThrownBy(() -> service.deleteMealEntry(99L)).isInstanceOf(BadRequestException.class);

		verify(mealEntryRepository, never()).delete(any());
	}

	@Test
	void deleteMealEntry_ownEntry_isDeleted() {
		MealEntry own = new MealEntry(currentUser, NOW, MealType.OGLE_YEMEGI);
		when(mealEntryRepository.findById(5L)).thenReturn(Optional.of(own));

		service.deleteMealEntry(5L);

		verify(mealEntryRepository).delete(own);
	}

	@Test
	void deleteMealItem_itemBelongsToAnotherUser_throwsAndDoesNotModify() {
		MealEntry foreign = new MealEntry(otherUser, NOW, MealType.OGLE_YEMEGI);
		MealItem item = new MealItem(foreign, food(10L), new BigDecimal("50"));
		foreign.addItem(item);
		when(mealItemRepository.findById(7L)).thenReturn(Optional.of(item));

		assertThatThrownBy(() -> service.deleteMealItem(7L)).isInstanceOf(BadRequestException.class);

		verify(mealEntryRepository, never()).delete(any());
		verify(mealEntryRepository, never()).saveAndFlush(any());
	}

	@Test
	void deleteMealItem_lastItemRemoved_deletesWholeEntryAndReturnsEmpty() {
		MealEntry own = new MealEntry(currentUser, NOW, MealType.OGLE_YEMEGI);
		MealItem only = new MealItem(own, food(10L), new BigDecimal("50"));
		own.addItem(only);
		when(mealItemRepository.findById(7L)).thenReturn(Optional.of(only));

		Optional<?> result = service.deleteMealItem(7L);

		// Boş öğün kaydı geride bırakılmamalı.
		assertThat(result).isEmpty();
		verify(mealEntryRepository).delete(own);
	}

	@Test
	void deleteMealItem_otherItemsRemain_keepsEntryAndReturnsResponse() {
		MealEntry own = new MealEntry(currentUser, NOW, MealType.OGLE_YEMEGI);
		MealItem first = new MealItem(own, food(10L), new BigDecimal("50"));
		MealItem second = new MealItem(own, food(11L), new BigDecimal("70"));
		own.addItem(first);
		own.addItem(second);
		when(mealItemRepository.findById(7L)).thenReturn(Optional.of(first));
		// Servis kalan kayit icin Optional.of(...) dondurur; mapper null verirse NPE
		// olur.
		when(nutritionMapper.toMealEntryResponse(any(), any())).thenReturn(mock(MealEntryResponse.class));

		service.deleteMealItem(7L);

		verify(mealEntryRepository, never()).delete(any());
		assertThat(own.getItems()).containsExactly(second);
	}

}
