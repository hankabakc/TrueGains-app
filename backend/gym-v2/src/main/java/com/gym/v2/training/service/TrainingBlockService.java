package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.service.NotificationService;
import com.gym.v2.core.service.TransactionalEvents;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.dto.WorkoutDayDTO;
import com.gym.v2.training.dto.WorkoutExerciseDTO;
import com.gym.v2.training.entity.Exercise;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.entity.WorkoutDay;
import com.gym.v2.training.entity.WorkoutExercise;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Antrenman programlarını (TrainingBlock), şablonları ve atama işlemlerini yöneten
 * servis.
 */
@Service
public class TrainingBlockService {

	private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(TrainingBlockService.class);

	private final TrainingBlockRepository blockRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository userRepository;

	private final ExerciseRepository exerciseRepository;

	private final TrainingMapper trainingMapper;

	private final SimpMessagingTemplate messagingTemplate;

	private final NotificationService notificationService;

	private final TransactionalEvents transactionalEvents;

	private final Clock clock;

	public TrainingBlockService(TrainingBlockRepository blockRepository, ClientRepository clientRepository,
			AppUserRepository userRepository, ExerciseRepository exerciseRepository, TrainingMapper trainingMapper,
			SimpMessagingTemplate messagingTemplate, NotificationService notificationService,
			TransactionalEvents transactionalEvents, Clock clock) {
		this.blockRepository = blockRepository;
		this.clientRepository = clientRepository;
		this.userRepository = userRepository;
		this.exerciseRepository = exerciseRepository;
		this.trainingMapper = trainingMapper;
		this.messagingTemplate = messagingTemplate;
		this.notificationService = notificationService;
		this.transactionalEvents = transactionalEvents;
		this.clock = clock;
	}

	@Transactional
	public TrainingBlockDTO createPersonalProgram(TrainingBlockDTO request) {
		AppUser currentUser = getCurrentUser();
		AppUser clientUser;
		AppUser coachUser = null;

		if (currentUser.getRole() == UserRole.COACH) {
			if (request.clientId() == null) {
				throw new BadRequestException("Programın atanacağı sporcu seçilmelidir.");
			}
			clientUser = userRepository.findById(request.clientId())
				.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
			var clientEntity = clientRepository.findByUserId(request.clientId())
				.orElseThrow(() -> new BadRequestException("Hedef kullanıcı bir sporcu değil."));
			if (clientEntity.getCoachId() == null || !clientEntity.getCoachId().equals(currentUser.getId())) {
				throw new BadRequestException("Sadece aktif öğrencilerinize program oluşturabilirsiniz.");
			}
			coachUser = currentUser;
		}
		else if (currentUser.getRole() == UserRole.CLIENT) {
			clientUser = currentUser;
		}
		else {
			throw new BadRequestException("Bu işlemi yalnızca antrenörler ve sporcular yapabilir.");
		}

		// DTO'da @NotNull var, ama servis doğrudan da çağrılabildiği için burada da
		// korunuyor: aşağıdaki plusWeeks çağrısı null tarihte NPE ile 500 üretirdi.
		if (request.startDate() == null) {
			throw new BadRequestException("Programın başlangıç tarihi zorunludur.");
		}

		TrainingBlock block = new TrainingBlock();
		block.setName(request.name());
		block.setDescription(request.description());
		block.setCoach(coachUser);
		block.setClient(clientUser);
		block.setStartDate(request.startDate());
		block.setDurationWeeks(request.durationWeeks() != null ? request.durationWeeks() : 4);
		block.setEndDate(request.startDate().plusWeeks(block.getDurationWeeks()));
		block.setIsActive(false);
		mapWorkoutDays(request.workoutDays(), block);

		TrainingBlock saved = blockRepository.saveAndFlush(block);
		return trainingMapper.toTrainingBlockDTO(saved);
	}

	@Transactional
	public TrainingBlockDTO updatePersonalProgram(Long id, TrainingBlockDTO request) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Program bulunamadı."));
		AppUser currentUser = getCurrentUser();

		boolean isAuthorized = false;
		if (currentUser.getRole() == UserRole.COACH) {
			isAuthorized = (block.getCoach() != null && block.getCoach().getId().equals(currentUser.getId()))
					|| (block.getClient() != null && clientRepository.findByUserId(block.getClient().getId())
						.map(client -> client.getCoachId() != null && client.getCoachId().equals(currentUser.getId()))
						.orElse(false));
		}
		else if (currentUser.getRole() == UserRole.CLIENT) {
			isAuthorized = block.getCoach() == null && block.getClient() != null
					&& block.getClient().getId().equals(currentUser.getId());
		}

		if (!isAuthorized) {
			throw new BadRequestException("Bu programı güncelleme yetkiniz yok.");
		}

		block.setName(request.name());
		block.setDescription(request.description());
		block.setStartDate(request.startDate());
		block.setDurationWeeks(request.durationWeeks() != null ? request.durationWeeks() : block.getDurationWeeks());
		block.setEndDate(request.startDate() != null ? request.startDate().plusWeeks(block.getDurationWeeks())
				: block.getEndDate());
		// `version` alanına elle yazılmaz: bu bir @Version (iyimser kilit) alanıdır ve
		// sürümü Hibernate artırır. Elle yazmak ya sürümü çift artırır ya da
		// UPDATE ... WHERE version = ? hiçbir satır bulamadığı için her güncellemeyi
		// OptimisticLockException'a çevirir. İki koçun aynı programı aynı anda
		// düzenlemesinde veri kaybını önleyen mekanizma budur; bozulmamalı.

		mapWorkoutDays(request.workoutDays(), block);
		TrainingBlock saved = blockRepository.saveAndFlush(block);

		if (currentUser.getRole() == UserRole.COACH && block.getClient() != null) {
			transactionalEvents.afterCommit(() -> messagingTemplate
				.convertAndSend("/topic/training/" + block.getClient().getId(), "REFRESH_REQUIRED"));
		}
		return trainingMapper.toTrainingBlockDTO(saved);
	}

	@Transactional
	public void deletePersonalProgram(Long id) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Program bulunamadı."));
		AppUser currentUser = getCurrentUser();

		boolean isOwner = block.getClient() != null && block.getClient().getId().equals(currentUser.getId());
		boolean isCoach = currentUser.getRole() == UserRole.COACH && ((block.getCoach() != null
				&& block.getCoach().getId().equals(currentUser.getId()))
				|| (block.getClient() != null && clientRepository.findByUserId(block.getClient().getId())
					.map(client -> client.getCoachId() != null && client.getCoachId().equals(currentUser.getId()))
					.orElse(false)));

		if (!isOwner && !isCoach) {
			throw new BadRequestException("Bu programı silme yetkiniz yok.");
		}

		blockRepository.delete(block);
	}

	@Transactional(readOnly = true)
	public List<TrainingBlockDTO> getMyActivePrograms() {
		AppUser currentUser = getCurrentUser();
		List<TrainingBlock> blocks = blockRepository.findByClientIdWithFetch(currentUser.getId());

		Long currentCoachId = clientRepository.findByUserId(currentUser.getId()).map(c -> c.getCoachId()).orElse(null);

		// Şablonların hâlâ var olup olmadığı program başına değil, tek sorguda
		// sorulur; aksi hâlde listenin maliyeti program sayısıyla birlikte büyür.
		Set<Long> referencedTemplateIds = blocks.stream()
			.map(TrainingBlock::getTemplateId)
			.filter(Objects::nonNull)
			.collect(Collectors.toSet());
		Set<Long> livingTemplateIds = referencedTemplateIds.isEmpty() ? Set.of()
				: new HashSet<>(blockRepository.findExistingIds(referencedTemplateIds));

		for (TrainingBlock block : blocks) {
			boolean orphanedByCoach = block.getCoach() != null
					&& (currentCoachId == null || !currentCoachId.equals(block.getCoach().getId()));
			boolean orphanedByTemplate = block.getTemplateId() != null
					&& !livingTemplateIds.contains(block.getTemplateId());
			block.setIsOrphaned(orphanedByCoach || orphanedByTemplate);
		}
		return blocks.stream().map(trainingMapper::toTrainingBlockDTO).toList();
	}

	@Transactional(readOnly = true)
	public List<TrainingBlockDTO> getCoachTemplates() {
		AppUser currentUser = getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu işlemi sadece antrenörler yapabilir.");
		}
		return blockRepository.findByCoachIdAndIsTemplateTrue(currentUser.getId())
			.stream()
			.map(trainingMapper::toTrainingBlockDTO)
			.toList();
	}

	@Transactional(readOnly = true)
	public List<TrainingBlockDTO> getCoachAssignedPrograms() {
		AppUser currentUser = getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu listeye sadece antrenörler erişebilir.");
		}
		return blockRepository.findByCoachIdAndIsTemplateFalse(currentUser.getId())
			.stream()
			.map(trainingMapper::toTrainingBlockDTO)
			.toList();
	}

	@Transactional
	public TrainingBlockDTO createCoachTemplate(TrainingBlockDTO request) {
		AppUser currentUser = getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Şablon oluşturma yetkiniz yok.");
		}

		TrainingBlock block = new TrainingBlock();
		block.setName(request.name());
		block.setDescription(request.description());
		block.setCoach(currentUser);
		block.setIsTemplate(true);
		block.setStartDate(LocalDate.now(clock));
		block.setDurationWeeks(request.durationWeeks() != null ? request.durationWeeks() : 4);
		block.setEndDate(LocalDate.now(clock).plusWeeks(block.getDurationWeeks()));
		block.setIsActive(true);

		mapWorkoutDays(request.workoutDays(), block);
		return trainingMapper.toTrainingBlockDTO(blockRepository.saveAndFlush(block));
	}

	@Transactional
	public TrainingBlockDTO updateCoachTemplate(Long id, TrainingBlockDTO request) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı."));
		AppUser currentUser = getCurrentUser();

		if (!block.getIsTemplate() || block.getCoach() == null
				|| !block.getCoach().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu şablonu güncelleme yetkiniz yok.");
		}

		block.setName(request.name());
		block.setDescription(request.description());
		block.setDurationWeeks(request.durationWeeks() != null ? request.durationWeeks() : block.getDurationWeeks());
		mapWorkoutDays(request.workoutDays(), block);
		TrainingBlock saved = blockRepository.saveAndFlush(block);

		blockRepository.findAssignedBlocksByTemplateId(id).forEach(assigned -> {
			assigned.setName(request.name());
			assigned.setDescription(request.description());
			mapWorkoutDays(alignDtoIdsWith(request.workoutDays(), assigned), assigned);
			blockRepository.saveAndFlush(assigned);
			if (assigned.getClient() != null) {
				Long clientId = assigned.getClient().getId();
				transactionalEvents.afterCommit(
						() -> messagingTemplate.convertAndSend("/topic/training/" + clientId, "REFRESH_REQUIRED"));
			}
		});

		return trainingMapper.toTrainingBlockDTO(saved);
	}

	@Transactional
	public void deleteCoachTemplate(Long id) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı."));
		AppUser currentUser = getCurrentUser();

		if (!block.getIsTemplate() || block.getCoach() == null
				|| !block.getCoach().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu şablonu silme yetkiniz yok.");
		}

		blockRepository.findAssignedBlocksByTemplateId(id).forEach(assigned -> {
			if (assigned.getClient() != null) {
				Long clientId = assigned.getClient().getId();
				transactionalEvents.afterCommit(
						() -> messagingTemplate.convertAndSend("/topic/training/" + clientId, "REFRESH_REQUIRED"));
			}
		});

		blockRepository.delete(block);
	}

	@Transactional
	public TrainingBlockDTO assignTemplateToClient(Long templateId, Long clientId) {
		AppUser currentUser = getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atama işlemi sadece antrenörler tarafından yapılabilir.");
		}

		TrainingBlock template = blockRepository.findById(templateId)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı."));

		// Şablon içeriği atama sırasında kopyalanıp yanıtta döndüğü için, sahiplik
		// kontrolü olmadan başka bir koçun programı okunabilir hâle gelir.
		if (!template.getIsTemplate() || template.getCoach() == null
				|| !template.getCoach().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Geçersiz şablon veya erişim yetkiniz yok.");
		}

		var clientEntity = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));
		if (clientEntity.getCoachId() == null || !clientEntity.getCoachId().equals(currentUser.getId())) {
			throw new BadRequestException("Sadece kendi aktif öğrencilerinize program atayabilirsiniz.");
		}

		AppUser clientUser = userRepository.findById(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));

		TrainingBlock newBlock = new TrainingBlock();
		newBlock.setName(template.getName());
		newBlock.setCoach(currentUser);
		newBlock.setClient(clientUser);
		newBlock.setIsTemplate(false);
		newBlock.setTemplateId(template.getId());
		newBlock.setStartDate(LocalDate.now(clock));
		newBlock.setDurationWeeks(template.getDurationWeeks() != null ? template.getDurationWeeks() : 4);
		newBlock.setEndDate(LocalDate.now(clock).plusWeeks(newBlock.getDurationWeeks()));
		newBlock.setIsActive(false);

		List<WorkoutDay> newDays = new ArrayList<>();
		if (template.getWorkoutDays() != null) {
			for (WorkoutDay tDay : template.getWorkoutDays()) {
				WorkoutDay nDay = new WorkoutDay(newBlock, tDay.getName(), tDay.getDayOrder());
				nDay.setIsMagnetEnabled(tDay.getIsMagnetEnabled());
				if (tDay.getExercises() != null) {
					for (WorkoutExercise tEx : tDay.getExercises()) {
						nDay.addExercise(new WorkoutExercise(nDay, tEx.getExercise(), tEx.getTargetSets(),
								tEx.getTargetReps(), tEx.getTargetWeight(), tEx.getRestTimeSeconds(),
								tEx.getSupersetGroupId(), tEx.getOrderIndex(), tEx.getIsToFailure()));
					}
				}
				newDays.add(nDay);
			}
		}
		newBlock.setWorkoutDays(newDays);
		TrainingBlock saved = blockRepository.save(newBlock);

		transactionalEvents
			.afterCommit(() -> messagingTemplate.convertAndSend("/topic/training/" + clientId, "REFRESH_REQUIRED"));
		notificationService.sendPushNotification(clientId, "Yeni Antrenman Programı!",
				"Antrenörünüz size yeni bir antrenman programı atadı: " + template.getName());

		return trainingMapper.toTrainingBlockDTO(saved);
	}

	@Transactional
	public void activateProgram(Long id) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Program bulunamadı."));
		AppUser currentUser = getCurrentUser();

		if (block.getClient() == null || !block.getClient().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu programı aktif etme yetkiniz yok.");
		}

		// Tek tek saveAndFlush yerine toplu kayıt: sporcunun her programı için ayrı bir
		// UPDATE turu atılıyordu, maliyet program sayısıyla büyüyordu.
		List<TrainingBlock> others = blockRepository.findByClientId(currentUser.getId())
			.stream()
			.filter(p -> Boolean.TRUE.equals(p.getIsActive()) && !p.getId().equals(block.getId()))
			.peek(p -> p.setIsActive(false))
			.toList();
		if (!others.isEmpty()) {
			blockRepository.saveAll(others);
		}

		block.setIsActive(true);
		blockRepository.saveAndFlush(block);
	}

	@Transactional
	public TrainingBlockDTO approveOrphanedProgram(Long id, boolean keep) {
		TrainingBlock block = blockRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Program bulunamadı."));
		AppUser currentUser = getCurrentUser();

		if (block.getClient() == null || !block.getClient().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu program üzerinde işlem yapma yetkiniz yok.");
		}

		if (keep) {
			block.setCoach(null);
			block.setTemplateId(null);
			TrainingBlock saved = blockRepository.saveAndFlush(block);
			return trainingMapper.toTrainingBlockDTO(saved);
		}
		else {
			deletePersonalProgram(id);
			return null;
		}
	}

	/**
	 * Şablon içeriğini atanmış bir kopyaya uygularken, DTO'daki kimlikleri kopyanın kendi
	 * satır kimlikleriyle değiştirir.
	 * <p>
	 * Atama sırasında günler ve egzersizler <b>kopyalanır</b>, yani kopyanın kimlikleri
	 * şablonunkilerden farklıdır. Şablonun DTO'su doğrudan kopyaya uygulanırsa
	 * {@link #mapWorkoutDays} hiçbir kimliği eşleştiremez, kopyanın tüm günlerini
	 * koleksiyondan atar ve {@code orphanRemoval} bunları veritabanından siler. Silinen
	 * {@code workout_exercises} satırları da {@code ON DELETE CASCADE} ile sporcunun
	 * {@code workout_logs} kayıtlarını götürür.
	 * </p>
	 * <p>
	 * Eşleştirme konuma göre yapılır: günler {@code dayOrder}, egzersizler
	 * {@code orderIndex} üzerinden. Karşılığı olmayan DTO {@code null} kimlikle geçer ve
	 * yeni satır olarak eklenir; kopyada kalan fazlalık satırlar silinir (koç o günü
	 * gerçekten kaldırmıştır).
	 * </p>
	 * <p>
	 * ponytail: konum bazlı eşleştirme, şablon düzenleyicideki mevcut yaklaşımla aynı.
	 * Bilinen tavan: koç bir pozisyondaki egzersizi başkasıyla değiştirirse o satırın
	 * hedefi değişir; geçmiş {@code workout_logs.performed_exercise_id} üzerinden doğru
	 * egzersize bağlı kalır. Kimlik bazlı eşleştirme gerekirse günlere/egzersizlere
	 * kalıcı bir {@code source_id} alanı eklenir.
	 * </p>
	 */
	private List<WorkoutDayDTO> alignDtoIdsWith(List<WorkoutDayDTO> dayDtos, TrainingBlock assigned) {
		if (dayDtos == null || assigned.getWorkoutDays() == null) {
			return dayDtos;
		}

		Map<Integer, WorkoutDay> assignedDaysByOrder = assigned.getWorkoutDays()
			.stream()
			.filter(day -> day.getDayOrder() != null)
			.collect(Collectors.toMap(WorkoutDay::getDayOrder, day -> day, (first, second) -> first));

		return dayDtos.stream().map(dayDto -> {
			WorkoutDay counterpart = assignedDaysByOrder.get(dayDto.dayOrder());
			if (counterpart == null) {
				return withIds(dayDto, null, Map.of());
			}
			Map<Integer, Long> exerciseIdsByOrder = counterpart.getExercises() == null ? Map.of()
					: counterpart.getExercises()
						.stream()
						.filter(we -> we.getOrderIndex() != null)
						.collect(Collectors.toMap(WorkoutExercise::getOrderIndex, WorkoutExercise::getId,
								(first, second) -> first));
			return withIds(dayDto, counterpart.getId(), exerciseIdsByOrder);
		}).toList();
	}

	/**
	 * Gün ve egzersiz kimlikleri değiştirilmiş bir kopya DTO üretir (record'lar
	 * değişmez).
	 */
	private WorkoutDayDTO withIds(WorkoutDayDTO dayDto, Long dayId, Map<Integer, Long> exerciseIdsByOrder) {
		List<WorkoutExerciseDTO> exercises = dayDto.exercises() == null ? null
				: dayDto.exercises()
					.stream()
					.map(ex -> new WorkoutExerciseDTO(exerciseIdsByOrder.get(ex.orderIndex()), ex.exerciseId(),
							ex.exerciseName(), ex.muscleGroup(), ex.targetSets(), ex.targetReps(), ex.targetWeight(),
							ex.restTimeSeconds(), ex.supersetGroupId(), ex.orderIndex(), ex.coachNotes(),
							ex.isToFailure(), ex.logs()))
					.toList();
		return new WorkoutDayDTO(dayId, dayDto.name(), dayDto.dayOrder(), dayDto.isMagnetEnabled(), exercises);
	}

	private void mapWorkoutDays(List<WorkoutDayDTO> dayDtos, TrainingBlock block) {
		if (dayDtos == null) {
			if (block.getWorkoutDays() != null) {
				block.getWorkoutDays().clear();
			}
			return;
		}
		if (block.getWorkoutDays() == null) {
			block.setWorkoutDays(new ArrayList<>());
		}

		Set<Long> dtoIds = dayDtos.stream().map(WorkoutDayDTO::id).filter(Objects::nonNull).collect(Collectors.toSet());
		block.getWorkoutDays().removeIf(d -> d.getId() != null && !dtoIds.contains(d.getId()));

		// Programdaki tüm egzersizler tek sorguda çekilir; gün gün veya egzersiz egzersiz
		// sorgulanırsa kaydetme maliyeti program büyüdükçe artar.
		Map<Long, Exercise> exercisesById = loadReferencedExercises(dayDtos);

		Map<Long, WorkoutDay> currentDaysMap = block.getWorkoutDays()
			.stream()
			.filter(d -> d.getId() != null)
			.collect(Collectors.toMap(WorkoutDay::getId, d -> d));

		for (WorkoutDayDTO dayDto : dayDtos) {
			WorkoutDay day;
			if (dayDto.id() != null && currentDaysMap.containsKey(dayDto.id())) {
				day = currentDaysMap.get(dayDto.id());
				day.setName(dayDto.name());
				day.setDayOrder(dayDto.dayOrder());
				day.setIsMagnetEnabled(dayDto.isMagnetEnabled() == null || dayDto.isMagnetEnabled());
			}
			else {
				day = new WorkoutDay(block, dayDto.name(), dayDto.dayOrder());
				day.setIsMagnetEnabled(dayDto.isMagnetEnabled() == null || dayDto.isMagnetEnabled());
				block.addWorkoutDay(day);
			}
			mapWorkoutExercises(dayDto.exercises(), day, exercisesById);
		}
	}

	/**
	 * İstekte geçen tüm egzersizleri tek sorguda getirir.
	 */
	private Map<Long, Exercise> loadReferencedExercises(List<WorkoutDayDTO> dayDtos) {
		Set<Long> exerciseIds = dayDtos.stream()
			.map(WorkoutDayDTO::exercises)
			.filter(Objects::nonNull)
			.flatMap(List::stream)
			.map(WorkoutExerciseDTO::exerciseId)
			.filter(Objects::nonNull)
			.collect(Collectors.toSet());

		if (exerciseIds.isEmpty()) {
			return Map.of();
		}
		return exerciseRepository.findAllById(exerciseIds)
			.stream()
			.collect(Collectors.toMap(Exercise::getId, exercise -> exercise));
	}

	private void mapWorkoutExercises(List<WorkoutExerciseDTO> exDtos, WorkoutDay day,
			Map<Long, Exercise> exercisesById) {
		if (exDtos == null) {
			if (day.getExercises() != null) {
				day.getExercises().clear();
			}
			return;
		}
		if (day.getExercises() == null) {
			day.setExercises(new ArrayList<>());
		}

		Set<Long> dtoIds = exDtos.stream()
			.map(WorkoutExerciseDTO::id)
			.filter(Objects::nonNull)
			.collect(Collectors.toSet());
		day.getExercises().removeIf(e -> e.getId() != null && !dtoIds.contains(e.getId()));

		Map<Long, WorkoutExercise> currentExMap = day.getExercises()
			.stream()
			.filter(e -> e.getId() != null)
			.collect(Collectors.toMap(WorkoutExercise::getId, e -> e));

		for (WorkoutExerciseDTO exDto : exDtos) {
			Exercise exercise = exercisesById.get(exDto.exerciseId());
			if (exercise == null) {
				throw new NotFoundException("Egzersiz bulunamadı: " + exDto.exerciseId());
			}

			if (exDto.id() != null && currentExMap.containsKey(exDto.id())) {
				WorkoutExercise we = currentExMap.get(exDto.id());
				we.setExercise(exercise);
				we.setTargetSets(exDto.targetSets());
				we.setTargetReps(exDto.targetReps());
				we.setTargetWeight(exDto.targetWeight());
				we.setRestTimeSeconds(exDto.restTimeSeconds() != null ? exDto.restTimeSeconds() : 60);
				we.setSupersetGroupId(exDto.supersetGroupId());
				we.setOrderIndex(exDto.orderIndex());
				we.setIsToFailure(exDto.isToFailure() != null && exDto.isToFailure());
			}
			else {
				day.addExercise(
						new WorkoutExercise(day, exercise, exDto.targetSets(), exDto.targetReps(), exDto.targetWeight(),
								exDto.restTimeSeconds() != null ? exDto.restTimeSeconds() : 60, exDto.supersetGroupId(),
								exDto.orderIndex(), exDto.isToFailure() != null && exDto.isToFailure()));
			}
		}
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
