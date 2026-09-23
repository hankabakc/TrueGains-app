package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.training.dto.WorkoutLogDTO;
import com.gym.v2.training.dto.WorkoutLogRequestDTO;
import com.gym.v2.training.dto.WorkoutSessionDTO;
import com.gym.v2.training.dto.WorkoutSessionRequestDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.entity.WorkoutLog;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.training.repository.WorkoutDayRepository;
import com.gym.v2.training.repository.WorkoutExerciseRepository;
import com.gym.v2.training.repository.WorkoutLogRepository;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Antrenman seanslarını (WorkoutSession) ve set loglarını yöneten servis.
 */
@Service
public class WorkoutSessionService {

	private final WorkoutSessionRepository workoutSessionRepository;

	private final WorkoutLogRepository logRepository;

	private final WorkoutExerciseRepository workoutExerciseRepository;

	private final ExerciseRepository exerciseRepository;

	private final AppUserRepository userRepository;

	private final ClientRepository clientRepository;

	private final WeeklyProgressService weeklyProgressService;

	private final TrainingBlockRepository trainingBlockRepository;

	private final WorkoutDayRepository workoutDayRepository;

	private final TrainingMapper trainingMapper;

	private final Clock clock;

	public WorkoutSessionService(WorkoutSessionRepository workoutSessionRepository, WorkoutLogRepository logRepository,
			WorkoutExerciseRepository workoutExerciseRepository, ExerciseRepository exerciseRepository,
			AppUserRepository userRepository, ClientRepository clientRepository,
			WeeklyProgressService weeklyProgressService, TrainingBlockRepository trainingBlockRepository,
			WorkoutDayRepository workoutDayRepository, TrainingMapper trainingMapper, Clock clock) {
		this.workoutSessionRepository = workoutSessionRepository;
		this.logRepository = logRepository;
		this.workoutExerciseRepository = workoutExerciseRepository;
		this.exerciseRepository = exerciseRepository;
		this.userRepository = userRepository;
		this.clientRepository = clientRepository;
		this.weeklyProgressService = weeklyProgressService;
		this.trainingBlockRepository = trainingBlockRepository;
		this.workoutDayRepository = workoutDayRepository;
		this.trainingMapper = trainingMapper;
		this.clock = clock;
	}

	@Transactional
	public WorkoutLogDTO logSet(Long workoutExerciseId, WorkoutLogDTO request) {
		AppUser currentUser = getCurrentUser();
		WorkoutExercise we = workoutExerciseRepository
			.findByIdAndWorkoutDay_TrainingBlock_Client_Id(workoutExerciseId, currentUser.getId())
			.orElseThrow(() -> new NotFoundException("Egzersiz bulunamadı veya bu idmana erişim yetkiniz yok."));

		WorkoutLog workoutLog = new WorkoutLog(we, request.setIndex(), request.actualWeight(), request.actualReps(),
				request.rpe(), request.durationSeconds());
		workoutLog.onPersist(clock.instant());
		return trainingMapper.toWorkoutLogDTO(logRepository.save(workoutLog));
	}

	@Transactional
	public WorkoutSessionDTO logWorkoutSession(WorkoutSessionRequestDTO request) {
		AppUser currentUser = getCurrentUser();
		// Tekrar koruması (G-79): cevabı yolda kaybolup yeniden gönderilen istek ikinci
		// oturum
		// açmaz, ilk kaydın cevabını alır. Haftalık ilerleme de ikinci kez güncellenmez.
		if (request.localId() != null) {
			Optional<WorkoutSession> existing = workoutSessionRepository
				.findByUserIdAndLocalIdWithLogs(currentUser.getId(), request.localId());
			if (existing.isPresent()) {
				return trainingMapper.toWorkoutSessionDTO(existing.get());
			}
		}
		WorkoutSession session = new WorkoutSession(currentUser, request.workoutDayName(), request.totalSeconds());
		// Sunucu kimliği olmayan (0 ya da negatif) program/gün yazılmaz; aşağıda
		// egzersizden alınır (G-74).
		final Long requestedBlockId = positiveOrNull(request.trainingBlockId());
		final Long requestedDayId = positiveOrNull(request.workoutDayId());
		Long effectiveBlockId = requestedBlockId;

		// K1-07: Sahiplik doğrulaması — yabancı programa veya güne oturum bağlanamaz
		// (IDOR koruması).
		if (requestedDayId != null) {
			if (requestedBlockId != null) {
				workoutDayRepository
					.findByIdAndBlockIdAndClientId(requestedDayId, requestedBlockId, currentUser.getId())
					.orElseThrow(() -> new NotFoundException(
							"Antrenman günü bulunamadı veya yetkiniz yok: " + requestedDayId));
			}
			else {
				WorkoutDay day = workoutDayRepository.findByIdAndClientId(requestedDayId, currentUser.getId())
					.orElseThrow(() -> new NotFoundException(
							"Antrenman günü bulunamadı veya yetkiniz yok: " + requestedDayId));
				effectiveBlockId = day.getTrainingBlock().getId();
			}
		}
		else if (requestedBlockId != null) {
			trainingBlockRepository.findByIdAndClientId(requestedBlockId, currentUser.getId())
				.orElseThrow(() -> new NotFoundException(
						"Antrenman programı bulunamadı veya yetkiniz yok: " + requestedBlockId));
		}

		session.setTrainingBlockId(effectiveBlockId);
		session.setWorkoutDayId(requestedDayId);
		session.setLocalId(request.localId());
		session.onPersist(clock.instant());

		if (request.logs() != null && !request.logs().isEmpty()) {
			Set<Long> exerciseIds = request.logs()
				.stream()
				.map(WorkoutLogRequestDTO::workoutExerciseId)
				.collect(Collectors.toSet());

			List<WorkoutExercise> exercises = workoutExerciseRepository
				.findAllByIdInAndWorkoutDay_TrainingBlock_Client_Id(exerciseIds, currentUser.getId());

			Map<Long, WorkoutExercise> exerciseMap = exercises.stream()
				.collect(Collectors.toMap(WorkoutExercise::getId, e -> e));

			// G-74: internetsiz oluşturulan programın egzersizi cihazın verdiği negatif
			// geçici kimlikle gelir; sunucu onu local_id'de saklıyor. Tek sorgu, sahibi
			// sporcuyla sınırlı.
			Set<String> localIds = exerciseIds.stream()
				.filter(id -> id != null && id < 0)
				.map(String::valueOf)
				.collect(Collectors.toSet());
			if (!localIds.isEmpty()) {
				workoutExerciseRepository.findAllByLocalIdsOfClient(localIds, currentUser.getId())
					.forEach(we -> exerciseMap.putIfAbsent(Long.valueOf(we.getLocalId()), we));
			}

			// Alternatif (substitute) egzersizler de tek sorguda çekilir. Daha önce set
			// başına findById çağrılıyordu: 30 setlik bir idmanda 30 fazladan sorgu.
			Set<Long> substituteIds = request.logs()
				.stream()
				.map(WorkoutLogRequestDTO::substituteExerciseId)
				.filter(java.util.Objects::nonNull)
				.collect(Collectors.toSet());
			Map<Long, Exercise> substitutesById = substituteIds.isEmpty() ? Map.of()
					: exerciseRepository.findAllById(substituteIds)
						.stream()
						.collect(Collectors.toMap(Exercise::getId, e -> e));

			for (WorkoutLogRequestDTO logReq : request.logs()) {
				WorkoutExercise exercise = exerciseMap.get(logReq.workoutExerciseId());
				if (exercise == null) {
					throw new NotFoundException("Egzersiz bulunamadı veya yetkiniz yok: " + logReq.workoutExerciseId());
				}
				// Sunucuya henüz gitmemiş programla yapılan antrenmanda (G-74) program ve
				// gün cihazda kimliksizdir: egzersizin bağlı olduğu gün ve programa
				// yazılır, haftalık ilerleme de böylece güncellenir.
				if (session.getTrainingBlockId() == null && logReq.workoutExerciseId() < 0) {
					session.setTrainingBlockId(exercise.getWorkoutDay().getTrainingBlock().getId());
					if (session.getWorkoutDayId() == null) {
						session.setWorkoutDayId(exercise.getWorkoutDay().getId());
					}
				}
				WorkoutLog workoutLog = new WorkoutLog(exercise, logReq.setIndex(), logReq.actualWeight(),
						logReq.actualReps(), logReq.rpe(), logReq.durationSeconds());
				if (logReq.substituteExerciseId() != null) {
					Exercise performed = substitutesById.get(logReq.substituteExerciseId());
					if (performed == null) {
						throw new NotFoundException("Egzersiz bulunamadı: " + logReq.substituteExerciseId());
					}
					workoutLog.setPerformedExercise(performed);
				}
				workoutLog.onPersist(clock.instant());
				session.addLog(workoutLog);
			}
		}

		WorkoutSession savedSession = workoutSessionRepository.save(session);

		if (savedSession.getTrainingBlockId() != null) {
			java.time.ZonedDateTime nowZoned = java.time.ZonedDateTime.ofInstant(savedSession.getCreatedAt(),
					clock.getZone());
			java.time.LocalDate weekStart = nowZoned
				.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY))
				.toLocalDate();
			weeklyProgressService.upsertWeeklyProgress(currentUser.getId(), savedSession.getTrainingBlockId(),
					weekStart);
		}

		return trainingMapper.toWorkoutSessionDTO(savedSession);
	}

	@Transactional(readOnly = true)
	public List<WorkoutSessionDTO> getWorkoutHistory() {
		AppUser currentUser = getCurrentUser();
		return trainingMapper
			.toWorkoutSessionDTOList(workoutSessionRepository.findHistoryWithLogs(currentUser.getId()));
	}

	@Transactional(readOnly = true)
	public List<WorkoutSessionDTO> getClientWorkoutHistory(Long clientId) {
		AppUser currentUser = getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu geçmişe sadece antrenörler erişebilir.");
		}
		var clientEntity = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
		if (clientEntity.getCoachId() == null || !clientEntity.getCoachId().equals(currentUser.getId())) {
			throw new BadRequestException("Sadece kendi aktif öğrencilerinizin antrenman geçmişini görebilirsiniz.");
		}
		return trainingMapper.toWorkoutSessionDTOList(workoutSessionRepository.findHistoryWithLogs(clientId));
	}

	@Transactional
	public void deleteWorkoutSession(Long sessionId) {
		AppUser currentUser = getCurrentUser();
		WorkoutSession session = workoutSessionRepository.findById(sessionId)
			.orElseThrow(() -> new NotFoundException("İdman kaydı bulunamadı: " + sessionId));
		if (!session.getUser().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu kayıt size ait değil.");
		}
		workoutSessionRepository.delete(session);
	}

	private static Long positiveOrNull(Long id) {
		return id != null && id > 0 ? id : null;
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
