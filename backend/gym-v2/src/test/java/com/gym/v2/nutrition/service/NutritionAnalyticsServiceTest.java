package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.NutritionDashboardResponse;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.repository.MealEntryRepository;
import com.gym.v2.nutrition.repository.MealItemRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Collections;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

import static java.math.BigDecimal.ZERO;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code NutritionAnalyticsService.getDashboardData} erişim kontrolü testleri.
 * <p>
 * Bu uç isteğe bağlı bir {@code targetUserId} alır: koç, kendi sporcusunun beslenme
 * panosunu görüntüleyebilir. Koruma iki katmanlıdır — çağıran <b>COACH</b> olmalı
 * <b>ve</b> hedef sporcu <b>o koça bağlı</b> olmalıdır. Biri eksik olursa bir kullanıcı
 * herhangi birinin beslenme geçmişini okuyabilir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class NutritionAnalyticsServiceTest {

	@Mock
	private MealEntryRepository mealEntryRepository;

	@Mock
	private MealItemRepository mealItemRepository;

	@Mock
	private DietProgramRepository dietProgramRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private ClientRepository clientRepository;

	private NutritionAnalyticsService service;

	private AppUser coach;

	private AppUser client;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T12:00:00Z"), ZoneOffset.UTC);
		service = new NutritionAnalyticsService(mealEntryRepository, mealItemRepository, dietProgramRepository,
				userContextService, clientRepository, fixedClock);

		coach = userWithId(2L, "koc@test.com", UserRole.COACH);
		client = userWithId(50L, "sporcu@test.com", UserRole.CLIENT);
	}

	/** Panoyu üretecek sorguların boş dönmesi yeterli; test erişim kontrolünü ölçüyor. */
	private void stubEmptyDashboardQueries() {
		lenient().when(dietProgramRepository.findByOwnerIdAndMainTrue(any())).thenReturn(Optional.empty());
		lenient().when(mealEntryRepository.findDailyNutrientTotals(any(), any(), any()))
			.thenReturn(Collections.emptyList());
		lenient().when(mealEntryRepository.findDailyMealBreakdown(any(), any(), any()))
			.thenReturn(Collections.emptyList());
		lenient().when(mealItemRepository.findFoodFrequency(any(), any(), any())).thenReturn(Collections.emptyList());
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setUser(client);
		entity.setCoachId(coachId);
		return entity;
	}

	@Test
	void getDashboardData_nonCoachRequestsAnotherUsersData_isDenied() {
		AppUser plainClient = userWithId(1L, "baska.sporcu@test.com", UserRole.CLIENT);
		when(userContextService.getCurrentUser()).thenReturn(plainClient);

		assertThatThrownBy(() -> service.getDashboardData(null, 50L)).isInstanceOf(AccessDeniedException.class);

		// Sporcu kaydı bile sorgulanmamalı; yetki kontrolü en başta yapılmalı.
		verify(clientRepository, never()).findByUserId(any());
	}

	@Test
	void getDashboardData_coachRequestsDataOfClientNotAssignedToThem_isDenied() {
		when(userContextService.getCurrentUser()).thenReturn(coach);
		// Sporcu başka bir koça (7) bağlı.
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(7L)));

		assertThatThrownBy(() -> service.getDashboardData(null, 50L)).isInstanceOf(AccessDeniedException.class);

		verify(mealEntryRepository, never()).findDailyNutrientTotals(any(), any(), any());
	}

	@Test
	void getDashboardData_coachRequestsUnknownClient_throwsNotFound() {
		when(userContextService.getCurrentUser()).thenReturn(coach);
		when(clientRepository.findByUserId(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getDashboardData(null, 404L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void getDashboardData_coachRequestsOwnClient_queriesTheClientsDataNotTheCoachs() {
		when(userContextService.getCurrentUser()).thenReturn(coach);
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		stubEmptyDashboardQueries();

		assertThatCode(() -> service.getDashboardData(null, 50L)).doesNotThrowAnyException();

		// Kritik: veri SPORCUNUN (50) kimliğiyle çekilmeli, koçun (2) değil.
		verify(mealEntryRepository).findDailyNutrientTotals(eq(50L), any(), any());
	}

	/**
	 * Program kimliği de istekten gelir. Sahiplik doğrulanmazsa pano, başkasının kalori
	 * ve makro hedeflerini gösterir.
	 */
	@Test
	void getDashboardData_programIdOfAnotherUser_isIgnored() {
		when(userContextService.getCurrentUser()).thenReturn(client);
		stubEmptyDashboardQueries();

		DietProgram foreignProgram = new DietProgram();
		foreignProgram.setId(77L);
		foreignProgram.setOwner(userWithId(1L, "baska.sporcu@test.com", UserRole.CLIENT));
		foreignProgram.setTargetCalories(new BigDecimal("3000"));
		when(dietProgramRepository.findById(77L)).thenReturn(Optional.of(foreignProgram));

		NutritionDashboardResponse response = service.getDashboardData(77L, null);

		assertThat(response.hasActiveProgram()).isFalse();
		// Yabancı programın hedefi analize sızmamalı.
		assertThat(response.nutrientAnalysis())
			.allSatisfy(item -> assertThat(item.target()).isEqualByComparingTo(ZERO));
	}

	@Test
	void getDashboardData_ownProgramId_isUsed() {
		when(userContextService.getCurrentUser()).thenReturn(client);
		stubEmptyDashboardQueries();

		DietProgram ownProgram = new DietProgram();
		ownProgram.setId(88L);
		ownProgram.setOwner(client);
		ownProgram.setTargetCalories(new BigDecimal("2000"));
		when(dietProgramRepository.findById(88L)).thenReturn(Optional.of(ownProgram));

		NutritionDashboardResponse response = service.getDashboardData(88L, null);

		assertThat(response.hasActiveProgram()).isTrue();
	}

	@Test
	void getDashboardData_withoutTargetUser_usesCallersOwnData() {
		when(userContextService.getCurrentUser()).thenReturn(client);
		stubEmptyDashboardQueries();

		assertThatCode(() -> service.getDashboardData(null, null)).doesNotThrowAnyException();

		verify(mealEntryRepository).findDailyNutrientTotals(eq(50L), any(), any());
		// Hedef kullanıcı verilmediğinde sporcu-koç eşleşmesi sorgulanmamalı.
		verify(clientRepository, never()).findByUserId(any());
	}

}
