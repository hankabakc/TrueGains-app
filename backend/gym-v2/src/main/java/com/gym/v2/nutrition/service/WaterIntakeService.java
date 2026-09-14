package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.CustomGlassResponse;
import com.gym.v2.nutrition.dto.WaterDailySummaryResponse;
import com.gym.v2.nutrition.dto.WaterDailyTotalResponse;
import com.gym.v2.nutrition.dto.WaterIntakeResponse;
import com.gym.v2.nutrition.entity.CustomGlass;
import com.gym.v2.nutrition.entity.WaterIntake;
import com.gym.v2.nutrition.entity.WaterTarget;
import com.gym.v2.nutrition.repository.CustomGlassRepository;
import com.gym.v2.nutrition.repository.WaterIntakeRepository;
import com.gym.v2.nutrition.repository.WaterTargetRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class WaterIntakeService {

	private final WaterIntakeRepository intakeRepository;

	private final WaterTargetRepository targetRepository;

	private final CustomGlassRepository glassRepository;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final Clock clock;

	public WaterIntakeService(WaterIntakeRepository intakeRepository, WaterTargetRepository targetRepository,
			CustomGlassRepository glassRepository, UserContextService userContextService,
			NutritionMapper nutritionMapper, Clock clock) {
		this.intakeRepository = intakeRepository;
		this.targetRepository = targetRepository;
		this.glassRepository = glassRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.clock = clock;
	}

	@Transactional
	public WaterIntakeResponse addWater(Integer amountMl) {
		AppUser user = userContextService.getCurrentUser();
		WaterIntake intake = new WaterIntake();
		intake.setUser(user);
		intake.setAmountMl(amountMl);
		intake.setIntakeDate(LocalDate.now(clock));
		intake.setCreatedAt(LocalDateTime.now(clock));

		WaterIntake saved = intakeRepository.save(intake);
		return nutritionMapper.toWaterResponse(saved);
	}

	@Transactional(readOnly = true)
	public WaterDailySummaryResponse getDailySummary(LocalDate date) {
		AppUser user = userContextService.getCurrentUser();
		Integer total = intakeRepository.getTotalIntakeByDate(user.getId(), date);
		Integer targetMl = targetRepository.findByUserIdAndValidToIsNull(user.getId())
			.map(WaterTarget::getTargetMl)
			.orElse(2500);

		List<WaterIntakeResponse> intakes = intakeRepository.findByUserIdAndIntakeDate(user.getId(), date)
			.stream()
			.map(nutritionMapper::toWaterResponse)
			.collect(Collectors.toList());

		List<CustomGlassResponse> customGlasses = glassRepository.findByUserIdOrderByCreatedAtAsc(user.getId())
			.stream()
			.map(nutritionMapper::toGlassResponse)
			.collect(Collectors.toList());

		return new WaterDailySummaryResponse(total != null ? total : 0, targetMl, intakes, customGlasses);
	}

	@Transactional
	public void updateTarget(Integer targetMl) {
		if (targetMl == null || targetMl <= 0) {
			throw new BadRequestException("Su hedefi 0'dan büyük olmalıdır.");
		}
		AppUser user = userContextService.getCurrentUser();
		LocalDateTime now = LocalDateTime.now(clock);

		// Tarihçeli takip: mevcut aktif hedefi (validTo = null) arşivle, yeni aktif hedef
		// ekle.
		targetRepository.findByUserIdAndValidToIsNull(user.getId()).ifPresent(active -> {
			active.setValidTo(now);
			targetRepository.save(active);
		});

		WaterTarget target = new WaterTarget(user, targetMl);
		target.setValidFrom(now);
		target.setCreatedAt(now);
		targetRepository.save(target);
	}

	@Transactional
	public void deleteCustomGlass(Long id) {
		AppUser currentUser = userContextService.getCurrentUser();
		CustomGlass glass = glassRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Özel bardak bulunamadı: " + id));
		if (!glass.getUser().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu bardak size ait değil.");
		}
		glassRepository.delete(glass);
	}

	@Transactional
	public void deleteWaterIntake(Long id) {
		AppUser currentUser = userContextService.getCurrentUser();
		WaterIntake intake = intakeRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Su kaydı bulunamadı: " + id));
		if (!intake.getUser().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu kayıt size ait değil.");
		}
		intakeRepository.delete(intake);
	}

	@Transactional(readOnly = true)
	public List<WaterDailyTotalResponse> getRangeSummary(LocalDate start, LocalDate end) {
		AppUser user = userContextService.getCurrentUser();
		List<Object[]> results = intakeRepository.getDailyTotalsByDateRange(user.getId(), start, end);

		Integer targetMl = targetRepository.findByUserIdAndValidToIsNull(user.getId())
			.map(WaterTarget::getTargetMl)
			.orElse(2500);

		return results.stream()
			.map(res -> new WaterDailyTotalResponse((LocalDate) res[0], ((Long) res[1]).intValue(), targetMl))
			.collect(Collectors.toList());
	}

	@Transactional
	public CustomGlassResponse addCustomGlass(String name, Integer sizeMl) {
		AppUser user = userContextService.getCurrentUser();
		CustomGlass glass = new CustomGlass();
		glass.setUser(user);
		glass.setName(name);
		glass.setSizeMl(sizeMl);

		CustomGlass saved = glassRepository.save(glass);
		return nutritionMapper.toGlassResponse(saved);
	}

}
