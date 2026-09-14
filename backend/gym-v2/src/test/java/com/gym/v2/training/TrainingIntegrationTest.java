package com.gym.v2.training;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.dto.WorkoutDayDTO;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.entity.MuscleGroup;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.service.TrainingService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.MockedStatic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@SpringBootTest
@ActiveProfiles("test")
public class TrainingIntegrationTest {

	@Autowired
	private TrainingService trainingService;

	@Autowired
	private TrainingBlockRepository blockRepository;

	@Autowired
	private ExerciseRepository exerciseRepository;

	@Autowired
	private AppUserRepository userRepository;

	@MockitoBean
	private SecurityUtils securityUtils;

	private MockedStatic<SecurityUtils> mockedSecurityUtils;

	@BeforeEach
	void setUp() {
		mockedSecurityUtils = mockStatic(SecurityUtils.class);
	}

	@AfterEach
	void tearDown() {
		mockedSecurityUtils.close();
	}

	@Test
	@Transactional
	public void testDeepSync_AddExercise_ShouldPersistInDatabase() {
		System.out.println("🚀 [TEST] Entegrasyon testi başlıyor...");

		// 1. GIVEN: Bir kullanıcı ve bir egzersiz kütüphanesi hazırlığı
		AppUser client = AppUser.builder()
			.email("integrator@gym.com")
			.password("password")
			.role(UserRole.CLIENT)
			.build();
		client = userRepository.saveAndFlush(client);

		Exercise exLib = new Exercise();
		exLib.setName("Test Press");
		exLib.setMuscleGroup(MuscleGroup.CHEST);
		exLib.onPersist(java.time.Instant.now());
		exLib = exerciseRepository.saveAndFlush(exLib);

		mockedSecurityUtils.when(SecurityUtils::getCurrentUserEmail).thenReturn("integrator@gym.com");

		// 2. Bir program oluştur (1 gün, 1 egzersiz)
		TrainingBlock block = new TrainingBlock("Test Program", "Desc", null, client, LocalDate.now(),
				LocalDate.now().plusMonths(1));
		block.setIsActive(true);
		block.setIsTemplate(false);

		WorkoutDay day = new WorkoutDay(block, "Day 1", 1);
		WorkoutExercise we = new WorkoutExercise(day, exLib, 3, "10", BigDecimal.TEN, 60, null, 0, false);
		day.addExercise(we);
		block.addWorkoutDay(day);

		block = blockRepository.saveAndFlush(block);
		Long blockId = block.getId();
		Long dayId = block.getWorkoutDays().get(0).getId();
		Long ex1Id = block.getWorkoutDays().get(0).getExercises().get(0).getId();

		System.out.println("✅ [TEST] Başlangıç verisi kaydedildi. Block ID: " + blockId);
		System.out.println("📊 [TEST] Mevcut Egzersiz Sayısı: " + block.getWorkoutDays().get(0).getExercises().size());

		// 3. WHEN: DTO ile 2. egzersizi ekleyerek UPDATE et
		WorkoutExerciseDTO d1 = new WorkoutExerciseDTO(ex1Id, exLib.getId(), "Test Press", null, 3, "10",
				BigDecimal.TEN, 60, null, 0, null, false, null);
		WorkoutExerciseDTO d2 = new WorkoutExerciseDTO(0L, exLib.getId(), "Test Press 2", null, 4, "12", BigDecimal.TEN,
				60, null, 1, null, false, null);

		WorkoutDayDTO dayDto = new WorkoutDayDTO(dayId, "Day 1", 1, true, List.of(d1, d2));
		TrainingBlockDTO request = new TrainingBlockDTO(blockId, "Updated Program", "Desc", null, null, client.getId(),
				null, LocalDate.now(), LocalDate.now().plusMonths(1), true, 4, List.of(dayDto), true, false, false);

		System.out.println("🔄 [TEST] UpdatePersonalProgram çağrılıyor...");
		trainingService.updatePersonalProgram(blockId, request);

		// 4. THEN: Veritabanından tekrar çek ve doğrula
		// Transactional olduğu için session içindeki veriyi alabilir, refresh yaparak
		// DB'den zorlayalım
		TrainingBlock updatedBlock = blockRepository.findById(blockId).orElseThrow();
		int finalCount = updatedBlock.getWorkoutDays().get(0).getExercises().size();

		System.out.println("🏁 [TEST] Final Egzersiz Sayısı: " + finalCount);

		assertEquals(2, finalCount, "Veritabanında egzersiz sayısı 2 olmalı!");
	}

}
