package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import org.springframework.security.access.AccessDeniedException;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.entity.MealType;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import com.gym.v2.nutrition.repository.MealEntryRepository;
import com.gym.v2.nutrition.repository.MealItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * Beslenme analitiği ve dashboard verilerini hazırlayan servis. Adım 2.3 kapsamında SQL
 * Aggregation (SUM/GROUP BY) ile optimize edildi. Artık yüzlerce MealEntry nesnesi
 * belleğe çekilmez.
 */
@Service
public class NutritionAnalyticsService {

	private static final BigDecimal PERCENTAGE_BASE = new BigDecimal("100");

	private final MealEntryRepository mealEntryRepository;

	private final MealItemRepository mealItemRepository;

	private final DietProgramRepository dietProgramRepository;

	private final UserContextService userContextService;

	private final ClientRepository clientRepository;

	private final Clock clock;

	public NutritionAnalyticsService(MealEntryRepository mealEntryRepository, MealItemRepository mealItemRepository,
			DietProgramRepository dietProgramRepository, UserContextService userContextService,
			ClientRepository clientRepository, Clock clock) {
		this.mealEntryRepository = mealEntryRepository;
		this.mealItemRepository = mealItemRepository;
		this.dietProgramRepository = dietProgramRepository;
		this.userContextService = userContextService;
		this.clientRepository = clientRepository;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public NutritionDashboardResponse getDashboardData(Long programId, Long targetUserId) {
		AppUser currentUser = userContextService.getCurrentUser();
		AppUser user = currentUser;

		if (targetUserId != null) {
			// Koç Yetki Kontrolü
			if (currentUser.getRole() != UserRole.COACH) {
				throw new AccessDeniedException("Bu işlemi yapmaya yetkiniz yoktur.");
			}

			// Sporcunun koçuna bağlı olup olmadığı kontrol edilecek
			ClientEntity client = clientRepository.findByUserId(targetUserId)
				.orElseThrow(() -> new NotFoundException("Sporcu kaydı bulunamadı."));

			if (!Objects.equals(client.getCoachId(), currentUser.getId())) {
				throw new AccessDeniedException("Bu sporcunun verilerine erişim yetkiniz yoktur.");
			}

			user = client.getUser();
		}
		Instant now = clock.instant();
		Instant startOfDay = now.truncatedTo(ChronoUnit.DAYS);
		Instant endOfDay = startOfDay.plus(1, ChronoUnit.DAYS);
		Instant startOfLast7Days = startOfDay.minus(6, ChronoUnit.DAYS);

		// Program kimliği istekten geldiği için sahibi doğrulanır; aksi hâlde başkasının
		// kalori/makro hedefleri panoda gösterilir. Sahibi tutmayan kimlik, bilinmeyen
		// kimlikle aynı şekilde "program yok" olarak ele alınır.
		final AppUser dashboardUser = user;
		DietProgram selectedProgram = (programId != null) ? dietProgramRepository.findById(programId)
			.filter(program -> program.getOwner() != null
					&& Objects.equals(program.getOwner().getId(), dashboardUser.getId()))
			.orElse(null) : dietProgramRepository.findByOwnerIdAndMainTrue(user.getId()).orElse(null);

		// Adım 2.3: SQL Aggregations (Döngü ve N+1 optimizasyonu)
		List<Object[]> dailyTotalsRaw = mealEntryRepository.findDailyNutrientTotals(user.getId(), startOfLast7Days,
				endOfDay);
		List<Object[]> dailyBreakdownRaw = mealEntryRepository.findDailyMealBreakdown(user.getId(), startOfLast7Days,
				endOfDay);

		// Verileri tarihe göre haritala
		Map<LocalDate, NutrientSummary> dailyTotalsMap = new HashMap<>();
		for (Object[] row : dailyTotalsRaw) {
			LocalDate date;
			if (row[0] instanceof java.time.LocalDate) {
				date = (java.time.LocalDate) row[0];
			}
			else {
				date = ((java.sql.Date) row[0]).toLocalDate();
			}
			dailyTotalsMap.put(date,
					new NutrientSummary((BigDecimal) row[1], (BigDecimal) row[2], (BigDecimal) row[3],
							(BigDecimal) row[4], (BigDecimal) row[5], (BigDecimal) row[6], (BigDecimal) row[7],
							(BigDecimal) row[8], (BigDecimal) row[9]));
		}

		Map<LocalDate, Map<MealType, BigDecimal>> dailyBreakdownMap = new HashMap<>();
		for (Object[] row : dailyBreakdownRaw) {
			LocalDate date;
			if (row[0] instanceof java.time.LocalDate) {
				date = (java.time.LocalDate) row[0];
			}
			else {
				date = ((java.sql.Date) row[0]).toLocalDate();
			}
			MealType type = MealType.valueOf((String) row[1]);
			BigDecimal calories = (BigDecimal) row[2];
			dailyBreakdownMap.computeIfAbsent(date, k -> new HashMap<>()).put(type, calories);
		}

		// Bugünün besin frekansı
		List<FoodFrequencyResponse> todayFoods = mealItemRepository
			.findFoodFrequency(user.getId(), startOfDay, endOfDay)
			.stream()
			.map(obj -> new FoodFrequencyResponse((String) obj[0], (Long) obj[1], (BigDecimal) obj[2],
					(BigDecimal) obj[3], (BigDecimal) obj[4], (BigDecimal) obj[5]))
			.toList();

		LocalDate today = startOfDay.atZone(ZoneOffset.UTC).toLocalDate();
		DailySummaryResponse daily = buildDailySummary(today, dailyTotalsMap, dailyBreakdownMap, todayFoods);

		WeeklySummaryResponse weekly = buildWeeklySummary(startOfLast7Days, dailyTotalsMap, dailyBreakdownMap,
				selectedProgram);

		List<FoodFrequencyResponse> frequentFoods = mealItemRepository
			.findFoodFrequency(user.getId(), startOfLast7Days, endOfDay)
			.stream()
			.map(obj -> new FoodFrequencyResponse((String) obj[0], (Long) obj[1], (BigDecimal) obj[2],
					(BigDecimal) obj[3], (BigDecimal) obj[4], (BigDecimal) obj[5]))
			.toList();

		List<NutrientAnalysisResponse> analysis = getDetailedAnalysis(weekly, selectedProgram);
		boolean hasActiveProgram = selectedProgram != null;

		return new NutritionDashboardResponse(daily, weekly, frequentFoods, analysis, hasActiveProgram);
	}

	private DailySummaryResponse buildDailySummary(LocalDate date, Map<LocalDate, NutrientSummary> totalsMap,
			Map<LocalDate, Map<MealType, BigDecimal>> breakdownMap, List<FoodFrequencyResponse> foods) {
		NutrientSummary sum = totalsMap.getOrDefault(date, NutrientSummary.empty());
		Map<MealType, BigDecimal> meals = breakdownMap.getOrDefault(date, Collections.emptyMap());

		List<MealTypeBreakdownResponse> mealBreakdown = new ArrayList<>();
		for (MealType type : MealType.values()) {
			BigDecimal mealTotal = meals.getOrDefault(type, BigDecimal.ZERO);
			BigDecimal percentage = sum.calories().compareTo(BigDecimal.ZERO) > 0
					? mealTotal.multiply(PERCENTAGE_BASE).divide(sum.calories(), 2, RoundingMode.HALF_UP)
					: BigDecimal.ZERO;
			mealBreakdown.add(new MealTypeBreakdownResponse(getMealLabel(type), mealTotal, percentage));
		}

		return new DailySummaryResponse(sum.calories(), sum.protein(), sum.carbs(), sum.fat(), sum.sugar(), sum.fiber(),
				sum.sodium(), sum.cholesterol(), sum.potassium(), mealBreakdown, foods);
	}

	private WeeklySummaryResponse buildWeeklySummary(Instant start, Map<LocalDate, NutrientSummary> totalsMap,
			Map<LocalDate, Map<MealType, BigDecimal>> breakdownMap, DietProgram program) {
		List<DailySummaryResponse> dailyLogs = new ArrayList<>();
		BigDecimal totalCal = BigDecimal.ZERO;
		BigDecimal totalPro = BigDecimal.ZERO;
		BigDecimal totalCarb = BigDecimal.ZERO;
		BigDecimal totalFat = BigDecimal.ZERO;
		BigDecimal totalSug = BigDecimal.ZERO;
		BigDecimal totalFib = BigDecimal.ZERO;
		BigDecimal totalSod = BigDecimal.ZERO;
		BigDecimal totalChol = BigDecimal.ZERO;
		BigDecimal totalPot = BigDecimal.ZERO;

		for (int i = 0; i < 7; i++) {
			LocalDate currentDate = start.plus(i, ChronoUnit.DAYS).atZone(ZoneOffset.UTC).toLocalDate();
			DailySummaryResponse daySum = buildDailySummary(currentDate, totalsMap, breakdownMap,
					Collections.emptyList());
			dailyLogs.add(daySum);

			totalCal = totalCal.add(daySum.calories());
			totalPro = totalPro.add(daySum.protein());
			totalCarb = totalCarb.add(daySum.carbs());
			totalFat = totalFat.add(daySum.fat());
			totalSug = totalSug.add(daySum.sugar());
			totalFib = totalFib.add(daySum.fiber());
			totalSod = totalSod.add(daySum.sodium());
			totalChol = totalChol.add(daySum.cholesterol());
			totalPot = totalPot.add(daySum.potassium());
		}

		BigDecimal targetCal = program != null ? program.getTargetCalories() : BigDecimal.ZERO;
		BigDecimal targetPro = program != null ? program.getTargetProtein() : BigDecimal.ZERO;
		BigDecimal targetCarb = program != null ? program.getTargetCarbs() : BigDecimal.ZERO;
		BigDecimal targetFat = program != null ? program.getTargetFat() : BigDecimal.ZERO;
		BigDecimal targetSugar = program != null ? program.getTargetSugar() : BigDecimal.ZERO;
		BigDecimal targetFiber = program != null ? program.getTargetFiber() : BigDecimal.ZERO;
		BigDecimal targetSodium = program != null ? program.getTargetSodium() : BigDecimal.ZERO;
		BigDecimal targetChol = program != null ? program.getTargetCholesterol() : BigDecimal.ZERO;
		BigDecimal targetPot = program != null ? program.getTargetPotassium() : BigDecimal.ZERO;

		return new WeeklySummaryResponse(dailyLogs, totalCal, totalPro, totalCarb, totalFat, totalSug, totalFib,
				totalSod, totalChol, totalPot, targetCal, targetPro, targetCarb, targetFat, targetSugar, targetFiber,
				targetSodium, targetChol, targetPot);
	}

	private String getMealLabel(MealType type) {
		if (type == null) {
			return "Diğer";
		}
		if (type == MealType.KAHVALTI) {
			return "Kahvaltı";
		}
		if (type == MealType.OGLE_YEMEGI) {
			return "Öğle Yemeği";
		}
		if (type == MealType.AKSAM_YEMEGI) {
			return "Akşam Yemeği";
		}
		return "Diğer";
	}

	private List<NutrientAnalysisResponse> getDetailedAnalysis(WeeklySummaryResponse weekly, DietProgram program) {
		List<NutrientAnalysisResponse> list = new ArrayList<>();
		BigDecimal multiplier = new BigDecimal(7);

		addAnalysis(list, "Kalori",
				(program != null ? program.getTargetCalories() : BigDecimal.ZERO).multiply(multiplier),
				weekly.totalCalories(), "kcal");
		addAnalysis(list, "Protein",
				(program != null ? program.getTargetProtein() : BigDecimal.ZERO).multiply(multiplier),
				weekly.totalProtein(), "g");
		addAnalysis(list, "Karbonhidrat",
				(program != null ? program.getTargetCarbs() : BigDecimal.ZERO).multiply(multiplier),
				weekly.totalCarbs(), "g");
		addAnalysis(list, "Yağ", (program != null ? program.getTargetFat() : BigDecimal.ZERO).multiply(multiplier),
				weekly.totalFat(), "g");

		BigDecimal totalSugar = weekly.dailyLogs()
			.stream()
			.map(DailySummaryResponse::sugar)
			.reduce(BigDecimal.ZERO, BigDecimal::add);
		BigDecimal totalFiber = weekly.dailyLogs()
			.stream()
			.map(DailySummaryResponse::fiber)
			.reduce(BigDecimal.ZERO, BigDecimal::add);
		BigDecimal totalSodium = weekly.dailyLogs()
			.stream()
			.map(DailySummaryResponse::sodium)
			.reduce(BigDecimal.ZERO, BigDecimal::add);
		BigDecimal totalChol = weekly.dailyLogs()
			.stream()
			.map(DailySummaryResponse::cholesterol)
			.reduce(BigDecimal.ZERO, BigDecimal::add);
		BigDecimal totalPot = weekly.dailyLogs()
			.stream()
			.map(DailySummaryResponse::potassium)
			.reduce(BigDecimal.ZERO, BigDecimal::add);

		addAnalysis(list, "Şeker", (program != null ? program.getTargetSugar() : BigDecimal.ZERO).multiply(multiplier),
				totalSugar, "g");
		addAnalysis(list, "Lif", (program != null ? program.getTargetFiber() : BigDecimal.ZERO).multiply(multiplier),
				totalFiber, "g");
		addAnalysis(list, "Sodyum",
				(program != null ? program.getTargetSodium() : BigDecimal.ZERO).multiply(multiplier), totalSodium,
				"mg");
		addAnalysis(list, "Kolesterol",
				(program != null ? program.getTargetCholesterol() : BigDecimal.ZERO).multiply(multiplier), totalChol,
				"mg");
		addAnalysis(list, "Potasyum",
				(program != null ? program.getTargetPotassium() : BigDecimal.ZERO).multiply(multiplier), totalPot,
				"mg");

		return list;
	}

	@Transactional
	public void updateNutritionGoals(UpdateNutritionGoalsRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();
		DietProgram mainProgram = dietProgramRepository.findByOwnerIdAndMainTrue(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Önce bir diyet programı oluşturup aktif etmelisiniz."));

		if (request.targetCalories() != null) {
			mainProgram.setTargetCalories(request.targetCalories());
		}
		if (request.targetProtein() != null) {
			mainProgram.setTargetProtein(request.targetProtein());
		}
		if (request.targetCarbs() != null) {
			mainProgram.setTargetCarbs(request.targetCarbs());
		}
		if (request.targetFat() != null) {
			mainProgram.setTargetFat(request.targetFat());
		}
		if (request.targetSugar() != null) {
			mainProgram.setTargetSugar(request.targetSugar());
		}
		if (request.targetFiber() != null) {
			mainProgram.setTargetFiber(request.targetFiber());
		}
		if (request.targetSodium() != null) {
			mainProgram.setTargetSodium(request.targetSodium());
		}
		if (request.targetCholesterol() != null) {
			mainProgram.setTargetCholesterol(request.targetCholesterol());
		}
		if (request.targetPotassium() != null) {
			mainProgram.setTargetPotassium(request.targetPotassium());
		}

		mainProgram.onUpdate(clock.instant());
		dietProgramRepository.save(mainProgram);
	}

	private void addAnalysis(List<NutrientAnalysisResponse> list, String name, BigDecimal target, BigDecimal reached,
			String unit) {
		list.add(new NutrientAnalysisResponse(name, target, reached, reached.subtract(target), unit));
	}

}
