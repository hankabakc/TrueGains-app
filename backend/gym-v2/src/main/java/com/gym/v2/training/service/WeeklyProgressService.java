package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.dto.ExerciseProgressRecord;
import com.gym.v2.training.dto.WeeklyProgressDTO;
import com.gym.v2.training.dto.WeeklyHistoryItemDTO;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutLog;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.entity.WeeklyProgress;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.repository.WeeklyProgressRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Sporcu gelişimini (Progress) ve haftalık istatistikleri hesaplayan servis.
 */
@Service
public class WeeklyProgressService {

	private final TrainingBlockRepository blockRepository;

	private final WorkoutSessionRepository workoutSessionRepository;

	private final WorkoutLogRepository logRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository userRepository;

	private final WeeklyProgressRepository weeklyProgressRepository;

	private final Clock clock;

	public WeeklyProgressService(TrainingBlockRepository blockRepository,
			WorkoutSessionRepository workoutSessionRepository, WorkoutLogRepository logRepository,
			ClientRepository clientRepository, AppUserRepository userRepository,
			WeeklyProgressRepository weeklyProgressRepository, Clock clock) {
		this.blockRepository = blockRepository;
		this.workoutSessionRepository = workoutSessionRepository;
		this.logRepository = logRepository;
		this.clientRepository = clientRepository;
		this.userRepository = userRepository;
		this.weeklyProgressRepository = weeklyProgressRepository;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public WeeklyProgressDTO getWeeklyProgress(Long clientId) {
		List<TrainingBlock> activeBlocks = blockRepository.findByClientIdAndIsActiveTrue(clientId);
		if (activeBlocks.isEmpty()) {
			return new WeeklyProgressDTO(0, 0, 0.0);
		}
		TrainingBlock activeBlock = activeBlocks.get(0);

		int targetDays = 0;
		if (activeBlock.getWorkoutDays() != null) {
			targetDays = (int) activeBlock.getWorkoutDays()
				.stream()
				.filter(d -> d.getExercises() != null && !d.getExercises().isEmpty())
				.count();
		}

		if (targetDays == 0) {
			return new WeeklyProgressDTO(0, 0, 0.0);
		}

		ZonedDateTime nowZoned = ZonedDateTime.now(clock.getZone());
		Instant start = nowZoned.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
			.truncatedTo(java.time.temporal.ChronoUnit.DAYS)
			.toInstant();
		Instant end = nowZoned.with(java.time.temporal.TemporalAdjusters.nextOrSame(java.time.DayOfWeek.SUNDAY))
			.withHour(23)
			.withMinute(59)
			.withSecond(59)
			.withNano(999999999)
			.toInstant();

		List<WorkoutSession> sessions = workoutSessionRepository
			.findByUserIdAndTrainingBlockIdAndCreatedAtBetween(clientId, activeBlock.getId(), start, end);
		long completedDays = sessions.stream()
			.map(s -> s.getWorkoutDayId() != null ? s.getWorkoutDayId().toString() : s.getWorkoutDayName())
			.distinct()
			.count();

		double pct = Math.min(100.0, ((double) completedDays / targetDays) * 100.0);
		return new WeeklyProgressDTO(targetDays, (int) completedDays, pct);
	}

	@Transactional
	public void upsertWeeklyProgress(Long userId, Long trainingBlockId, LocalDate weekStartDate) {
		TrainingBlock block = blockRepository.findById(trainingBlockId)
			.orElseThrow(() -> new NotFoundException("Antrenman programı bulunamadı."));

		int targetDays = 0;
		if (block.getWorkoutDays() != null) {
			targetDays = (int) block.getWorkoutDays()
				.stream()
				.filter(d -> d.getExercises() != null && !d.getExercises().isEmpty())
				.count();
		}

		if (targetDays == 0) {
			return;
		}

		ZonedDateTime startZoned = weekStartDate.atStartOfDay(clock.getZone());
		Instant start = startZoned.toInstant();
		// getWeeklyProgress ile ayni pencere: nano dahil gun sonuna kadar.
		Instant end = startZoned.plusDays(6).withHour(23).withMinute(59).withSecond(59).withNano(999999999).toInstant();

		List<WorkoutSession> sessions = workoutSessionRepository
			.findByUserIdAndTrainingBlockIdAndCreatedAtBetween(userId, trainingBlockId, start, end);
		long completedDays = sessions.stream()
			.map(s -> s.getWorkoutDayId() != null ? s.getWorkoutDayId().toString() : s.getWorkoutDayName())
			.distinct()
			.count();

		double pct = Math.min(100.0, ((double) completedDays / targetDays) * 100.0);

		Optional<WeeklyProgress> existingProgress = weeklyProgressRepository
			.findByUserIdAndTrainingBlockIdAndWeekStartDate(userId, trainingBlockId, weekStartDate);

		if (existingProgress.isPresent()) {
			WeeklyProgress progress = existingProgress.get();
			progress.setTargetDays(targetDays);
			progress.setCompletedDays((int) completedDays);
			progress.setCompletionRate(pct);
			progress.setUpdatedAt(clock.instant());
			weeklyProgressRepository.save(progress);
		}
		else {
			WeeklyProgress progress = new WeeklyProgress(userId, trainingBlockId, weekStartDate, targetDays,
					(int) completedDays, pct);
			weeklyProgressRepository.save(progress);
		}
	}

	@Transactional(readOnly = true)
	public List<WeeklyHistoryItemDTO> getWeeklyHistory(Long clientId) {
		List<WeeklyProgress> progressList = weeklyProgressRepository.findByUserIdOrderByWeekStartDateDesc(clientId);
		List<WeeklyHistoryItemDTO> history = new ArrayList<>();
		for (WeeklyProgress wp : progressList) {
			history.add(new WeeklyHistoryItemDTO(wp.getWeekStartDate(), wp.getTargetDays(), wp.getCompletedDays(),
					wp.getCompletionRate()));
		}
		return history;
	}

	@Transactional(readOnly = true)
	public List<WeeklyHistoryItemDTO> getWeeklyHistoryForCurrentUser() {
		AppUser user = getCurrentUser();
		if (user.getRole() != UserRole.CLIENT) {
			throw new BadRequestException("Bu bilgiye sadece sporcular erişebilir.");
		}
		return getWeeklyHistory(user.getId());
	}

	@Transactional(readOnly = true)
	public List<WeeklyHistoryItemDTO> getWeeklyHistoryForCoach(Long clientId) {
		AppUser user = getCurrentUser();
		if (user.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu bilgiye sadece antrenörler erişebilir.");
		}
		var client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
		if (client.getCoachId() == null || !client.getCoachId().equals(user.getId())) {
			throw new BadRequestException("Sadece kendi aktif öğrencilerinizin ilerlemesini görebilirsiniz.");
		}
		return getWeeklyHistory(clientId);
	}

	@Transactional(readOnly = true)
	public WeeklyProgressDTO getWeeklyProgressForCurrentUser() {
		AppUser user = getCurrentUser();
		if (user.getRole() != UserRole.CLIENT) {
			throw new BadRequestException("Bu bilgiye sadece sporcular erişebilir.");
		}
		return getWeeklyProgress(user.getId());
	}

	@Transactional(readOnly = true)
	public WeeklyProgressDTO getWeeklyProgressForCoach(Long clientId) {
		AppUser user = getCurrentUser();
		if (user.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu bilgiye sadece antrenörler erişebilir.");
		}
		var client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
		if (client.getCoachId() == null || !client.getCoachId().equals(user.getId())) {
			throw new BadRequestException("Sadece kendi aktif öğrencilerinizin ilerlemesini görebilirsiniz.");
		}
		return getWeeklyProgress(clientId);
	}

	@Transactional(readOnly = true)
	public List<ExerciseProgressRecord> getExerciseProgress(Long exerciseId) {
		return buildExerciseProgress(getCurrentUser().getId(), exerciseId);
	}

	@Transactional(readOnly = true)
	public List<ExerciseProgressRecord> getExerciseProgressForCoach(Long clientId, Long exerciseId) {
		AppUser user = getCurrentUser();
		if (user.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu bilgiye sadece antrenörler erişebilir.");
		}
		var client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
		if (client.getCoachId() == null || !client.getCoachId().equals(user.getId())) {
			throw new BadRequestException("Sadece kendi aktif öğrencilerinizin ilerlemesini görebilirsiniz.");
		}
		return buildExerciseProgress(clientId, exerciseId);
	}

	private List<ExerciseProgressRecord> buildExerciseProgress(Long userId, Long exerciseId) {
		List<WorkoutLog> logs = logRepository.findAllByUserIdAndExerciseIdOrderByCreatedAtAsc(userId, exerciseId);
		if (logs.isEmpty()) {
			return Collections.emptyList();
		}

		Map<Long, List<WorkoutLog>> bySession = logs.stream()
			.filter(l -> l.getSession() != null)
			.collect(Collectors.groupingBy(l -> l.getSession().getId(), LinkedHashMap::new, Collectors.toList()));

		List<ExerciseProgressRecord> progress = new ArrayList<>();
		for (List<WorkoutLog> sessionLogs : bySession.values()) {
			BigDecimal max1RM = BigDecimal.ZERO;
			BigDecimal maxWeight = BigDecimal.ZERO;
			int totalSets = sessionLogs.size();
			Instant date = sessionLogs.getFirst().getCreatedAt();

			for (WorkoutLog entry : sessionLogs) {
				BigDecimal weight = entry.getActualWeight();
				Integer reps = entry.getActualReps();
				if (weight.compareTo(maxWeight) > 0) {
					maxWeight = weight;
				}

				BigDecimal oneRM;
				if (reps == null || reps <= 1) {
					oneRM = weight;
				}
				else {
					BigDecimal multiplier = BigDecimal.valueOf(reps)
						.divide(new BigDecimal("30.0"), MathContext.DECIMAL128)
						.add(BigDecimal.ONE);
					oneRM = weight.multiply(multiplier).setScale(2, RoundingMode.HALF_UP);
				}

				if (oneRM.compareTo(max1RM) > 0) {
					max1RM = oneRM;
				}
			}
			progress.add(new ExerciseProgressRecord(date, max1RM, maxWeight, totalSets));
		}
		return progress;
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
