package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.entity.CustomGlass;
import com.gym.v2.nutrition.entity.WaterIntake;
import com.gym.v2.nutrition.repository.CustomGlassRepository;
import com.gym.v2.nutrition.repository.WaterIntakeRepository;
import com.gym.v2.nutrition.repository.WaterTargetRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code WaterIntakeService} silme yollarının sahiplik kontrolü.
 * <p>
 * Su kaydı ve özel bardak kimlikleri URL'den gelir; koruma olmazsa bir kullanıcı
 * başkasının kayıtlarını silebilir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class WaterIntakeServiceTest {

	@Mock
	private WaterIntakeRepository intakeRepository;

	@Mock
	private WaterTargetRepository targetRepository;

	@Mock
	private CustomGlassRepository glassRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private NutritionMapper nutritionMapper;

	private WaterIntakeService service;

	private AppUser currentUser;

	private AppUser otherUser;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new WaterIntakeService(intakeRepository, targetRepository, glassRepository, userContextService,
				nutritionMapper, fixedClock);

		currentUser = userWithId(1L, "client@test.com");
		otherUser = userWithId(2L, "baskasi@test.com");
		lenient().when(userContextService.getCurrentUser()).thenReturn(currentUser);
	}

	@Test
	void deleteCustomGlass_glassBelongsToAnotherUser_throwsAndDeletesNothing() {
		CustomGlass glass = new CustomGlass();
		glass.setUser(otherUser);
		when(glassRepository.findById(5L)).thenReturn(Optional.of(glass));

		assertThatThrownBy(() -> service.deleteCustomGlass(5L)).isInstanceOf(BadRequestException.class);

		verify(glassRepository, never()).delete(any());
	}

	@Test
	void deleteCustomGlass_unknownGlass_throwsNotFound() {
		when(glassRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.deleteCustomGlass(404L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void deleteCustomGlass_ownGlass_isDeleted() {
		CustomGlass glass = new CustomGlass();
		glass.setUser(currentUser);
		when(glassRepository.findById(5L)).thenReturn(Optional.of(glass));

		service.deleteCustomGlass(5L);

		verify(glassRepository).delete(glass);
	}

	@Test
	void deleteWaterIntake_recordBelongsToAnotherUser_throwsAndDeletesNothing() {
		WaterIntake intake = new WaterIntake();
		intake.setUser(otherUser);
		when(intakeRepository.findById(7L)).thenReturn(Optional.of(intake));

		assertThatThrownBy(() -> service.deleteWaterIntake(7L)).isInstanceOf(BadRequestException.class);

		verify(intakeRepository, never()).delete(any());
	}

	@Test
	void deleteWaterIntake_ownRecord_isDeleted() {
		WaterIntake intake = new WaterIntake();
		intake.setUser(currentUser);
		when(intakeRepository.findById(7L)).thenReturn(Optional.of(intake));

		service.deleteWaterIntake(7L);

		verify(intakeRepository).delete(intake);
	}

}
