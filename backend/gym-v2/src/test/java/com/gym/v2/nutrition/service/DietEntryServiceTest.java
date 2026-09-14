package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.entity.DietDay;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.Meal;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.repository.MealEntryRepository;
import com.gym.v2.nutrition.repository.MealRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Collections;
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
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code DietEntryService.togglePlannedMeal} birim testleri.
 * <p>
 * Bu metot kullanıcının "bu öğünü yedim" işaretini kalıcı hâle getirir. İki risk taşır:
 * başka bir kullanıcının programındaki öğünün işaretlenebilmesi (IDOR) ve aynı öğün için
 * mükerrer kayıt birikerek günlük makro toplamının şişmesi.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class DietEntryServiceTest {

	@Mock
	private MealEntryRepository mealEntryRepository;

	@Mock
	private DietProgramRepository dietProgramRepository;

	@Mock
	private MealRepository mealRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private NutritionMapper nutritionMapper;

	@Mock
	private NutrientCalculator nutrientCalculator;

	private static final LocalDate DATE = LocalDate.of(2026, 1, 1);

	private DietEntryService service;

	private AppUser currentUser;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new DietEntryService(mealEntryRepository, dietProgramRepository, mealRepository, userContextService,
				nutritionMapper, nutrientCalculator, fixedClock);

		currentUser = userWithId(1L, "client@test.com");
		lenient().when(userContextService.getCurrentUser()).thenReturn(currentUser);
	}

	/** Sahibi {@code owner} olan bir programa bağlı planlı öğün üretir. */
	private Meal plannedMealOwnedBy(AppUser owner) {
		DietProgram program = new DietProgram();
		program.setOwner(owner);

		DietDay day = new DietDay();
		day.setDietProgram(program);

		Meal meal = new Meal();
		meal.setId(55L);
		meal.setDietDay(day);
		meal.setMealType(MealType.KAHVALTI);
		meal.setIngredients(Collections.emptyList());
		return meal;
	}

	private MealEntry existingLogFor(Long plannedMealId) {
		MealEntry entry = new MealEntry(currentUser, Instant.parse("2026-01-01T08:00:00Z"), MealType.KAHVALTI);
		entry.setPlannedMealId(plannedMealId);
		return entry;
	}

	// ---------------------------------------------------------------------------
	// İşareti kaldırma
	// ---------------------------------------------------------------------------

	@Test
	void togglePlannedMeal_markedAsNotConsumed_deletesExistingLogs() {
		MealEntry existing = existingLogFor(55L);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(existing));

		assertThat(service.togglePlannedMeal(DATE, 55L, false, null)).isNull();

		verify(mealEntryRepository).deleteAll(List.of(existing));
	}

	@Test
	void togglePlannedMeal_markedAsNotConsumedWithoutExistingLog_deletesNothing() {
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(Collections.emptyList());

		assertThat(service.togglePlannedMeal(DATE, 55L, false, null)).isNull();

		verify(mealEntryRepository, never()).deleteAll(any());
	}

	@Test
	void togglePlannedMeal_notConsumed_onlyTouchesTheTargetedMealNotOtherMeals() {
		MealEntry otherMeal = existingLogFor(99L);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(otherMeal));

		service.togglePlannedMeal(DATE, 55L, false, null);

		// Farklı bir planlı öğüne ait kayıt asla silinmemeli.
		verify(mealEntryRepository, never()).deleteAll(any());
	}

	// ---------------------------------------------------------------------------
	// Sahiplik (IDOR) ve bulunamayan öğün
	// ---------------------------------------------------------------------------

	@Test
	void togglePlannedMeal_unknownMeal_throwsNotFound() {
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(Collections.emptyList());
		when(mealRepository.findById(55L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.togglePlannedMeal(DATE, 55L, true, List.of(1L)))
			.isInstanceOf(NotFoundException.class);
	}

	@Test
	void togglePlannedMeal_mealBelongsToAnotherUsersProgram_throwsAndSavesNothing() {
		AppUser someoneElse = userWithId(2L, "baskasi@test.com");
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(Collections.emptyList());
		when(mealRepository.findById(55L)).thenReturn(Optional.of(plannedMealOwnedBy(someoneElse)));

		assertThatThrownBy(() -> service.togglePlannedMeal(DATE, 55L, true, List.of(1L)))
			.isInstanceOf(BadRequestException.class);

		verify(mealEntryRepository, never()).save(any());
	}

	@Test
	void togglePlannedMeal_existingLogButMealOfAnotherUser_throwsBeforeModifyingLog() {
		AppUser someoneElse = userWithId(2L, "baskasi@test.com");
		MealEntry existing = existingLogFor(55L);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(existing));
		when(mealRepository.findById(55L)).thenReturn(Optional.of(plannedMealOwnedBy(someoneElse)));

		assertThatThrownBy(() -> service.togglePlannedMeal(DATE, 55L, true, List.of(1L)))
			.isInstanceOf(BadRequestException.class);

		verify(mealEntryRepository, never()).save(any());
	}

	// ---------------------------------------------------------------------------
	// Mükerrer kayıt temizliği ve yeniden hesaplama
	// ---------------------------------------------------------------------------

	@Test
	void togglePlannedMeal_duplicateLogsForSameMeal_keepsOneAndDeletesTheRest() {
		MealEntry first = existingLogFor(55L);
		MealEntry duplicate = existingLogFor(55L);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(first, duplicate));
		when(mealRepository.findById(55L)).thenReturn(Optional.of(plannedMealOwnedBy(currentUser)));
		when(mealEntryRepository.save(any(MealEntry.class))).thenAnswer(i -> i.getArgument(0));

		service.togglePlannedMeal(DATE, 55L, true, List.of(1L));

		// Mükerrer kayıtlar kalırsa günlük makro toplamı iki kez sayılır.
		verify(mealEntryRepository).deleteAll(List.of(duplicate));
	}

	@Test
	void togglePlannedMeal_existingLog_rebuildsItemsAndRecalculatesTotals() {
		MealEntry existing = existingLogFor(55L);
		when(mealEntryRepository.findDailyLogs(any(), any(), any())).thenReturn(List.of(existing));
		when(mealRepository.findById(55L)).thenReturn(Optional.of(plannedMealOwnedBy(currentUser)));
		when(mealEntryRepository.save(any(MealEntry.class))).thenAnswer(i -> i.getArgument(0));

		service.togglePlannedMeal(DATE, 55L, true, List.of(1L));

		// Eski kalemler temizlenmezse seçim değiştiğinde toplam yanlış birikir.
		assertThat(existing.getItems()).isEmpty();
		verify(nutrientCalculator).calculateMealEntryTotals(existing);
		verify(mealEntryRepository).save(existing);
	}

}
