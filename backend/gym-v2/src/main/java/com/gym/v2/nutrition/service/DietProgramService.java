package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.*;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.gym.v2.nutrition.event.DietTemplateUpdatedEvent;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Clock;
import java.util.*;

/**
 * DietProgramService - Manages DietProgram lifecycle (CRUD, Activation, Copy). Adheres to
 * SRP by focusing only on Program entities. Macro overrides are delegated to
 * NutritionMapper.
 */
@Service
public class DietProgramService {

	private static final Logger log = LoggerFactory.getLogger(DietProgramService.class);

	private final DietProgramRepository programRepository;

	private final UserContextService userContextService;

	private final NutritionMapper nutritionMapper;

	private final AuditLogService auditLogService;

	private final Clock clock;

	private final ApplicationEventPublisher eventPublisher;

	private final SimpMessagingTemplate messagingTemplate;

	private final ClientRepository clientRepository;

	public DietProgramService(DietProgramRepository programRepository, UserContextService userContextService,
			NutritionMapper nutritionMapper, AuditLogService auditLogService, Clock clock,
			ApplicationEventPublisher eventPublisher, SimpMessagingTemplate messagingTemplate,
			ClientRepository clientRepository) {
		this.programRepository = programRepository;
		this.userContextService = userContextService;
		this.nutritionMapper = nutritionMapper;
		this.auditLogService = auditLogService;
		this.clock = clock;
		this.eventPublisher = eventPublisher;
		this.messagingTemplate = messagingTemplate;
		this.clientRepository = clientRepository;
	}

	@Transactional(readOnly = true)
	public List<DietProgramResponse> getMyPrograms() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<DietProgram> programs = programRepository.findByOwnerId(currentUser.getId());
		Long currentCoachId = clientRepository.findByUserId(currentUser.getId()).map(c -> c.getCoachId()).orElse(null);
		for (DietProgram program : programs) {
			boolean orphaned = program.getCoach() != null
					&& (currentCoachId == null || !currentCoachId.equals(program.getCoach().getId()));
			program.setOrphaned(orphaned);
		}
		return programs.stream().map(p -> nutritionMapper.toProgramResponse(p, currentUser.getId())).toList();
	}

	@Transactional(readOnly = true)
	public DietProgramResponse getMainProgram() {
		AppUser currentUser = userContextService.getCurrentUser();
		return programRepository.findByOwnerIdAndMainTrue(currentUser.getId())
			.map(p -> nutritionMapper.toProgramResponse(p, currentUser.getId()))
			.orElse(null);
	}

	@Transactional(readOnly = true)
	public DietProgramResponse getProgram(Long id) {
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		AppUser currentUser = userContextService.getCurrentUser();
		boolean isOwner = program.getOwner().getId().equals(currentUser.getId());
		boolean isCoachOfProgram = program.getCoach() != null && program.getCoach().getId().equals(currentUser.getId());

		if (!isOwner && !isCoachOfProgram) {
			throw new BadRequestException("Bu diyet programına erişim yetkiniz yok!");
		}

		return nutritionMapper.toProgramResponse(program, program.getOwner().getId());
	}

	@Transactional
	public DietProgramResponse createProgram(String name, boolean isMain) {
		AppUser currentUser = userContextService.getCurrentUser();

		if (isMain) {
			programRepository.findByOwnerIdAndMainTrue(currentUser.getId()).ifPresent(p -> {
				p.setMain(false);
				programRepository.saveAndFlush(p);
			});
		}

		DietProgram program = new DietProgram(currentUser, name, DietSource.CLIENT);
		program.setMain(isMain);
		program.onPersist(clock.instant());

		setDefaultGoals(program);

		for (int i = 1; i <= 7; i++) {
			DietDay dietDay = new DietDay(program, i, "Gün " + i);
			dietDay.getMeals().add(new Meal(dietDay, MealType.KAHVALTI, 0));
			dietDay.getMeals().add(new Meal(dietDay, MealType.OGLE_YEMEGI, 1));
			dietDay.getMeals().add(new Meal(dietDay, MealType.AKSAM_YEMEGI, 2));
			dietDay.getMeals().add(new Meal(dietDay, MealType.OTHER, 3));
			program.getDietDays().add(dietDay);
		}

		DietProgram saved = programRepository.save(program);
		auditLogService.log("DIET_PROGRAM_CREATED", currentUser.getEmail(), "Yeni diyet programı oluşturuldu: " + name);
		// Uygulama loglarına e-posta yazılmaz (KVKK); kimlik yeterli. Denetim kaydı ayrı
		// ve
		// bilinçli olarak e-postayı tutuyor.
		log.info("[DIET] Program oluşturuldu. ID: {}, UserID: {}", saved.getId(), currentUser.getId());
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	@Transactional
	public void activateProgram(Long id) {
		AppUser currentUser = userContextService.getCurrentUser();
		programRepository.findByOwnerIdAndMainTrue(currentUser.getId()).ifPresent(p -> {
			p.setMain(false);
			programRepository.saveAndFlush(p);
		});

		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		if (!program.getOwner().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu program size ait değil!");
		}

		program.setMain(true);
		programRepository.save(program);
		auditLogService.log("DIET_PROGRAM_ACTIVATED", currentUser.getEmail(), "Diyet programı aktif edildi. ID: " + id);
	}

	@Transactional
	public DietProgramResponse updateProgramGoals(Long id, UpdateNutritionGoalsRequest request) {
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		AppUser currentUser = userContextService.getCurrentUser();
		validateOwnershipAndModifiability(program, currentUser);

		if (isAnyNegative(request.targetCalories(), request.targetProtein(), request.targetCarbs(), request.targetFat(),
				request.targetSugar(), request.targetFiber(), request.targetSodium(), request.targetCholesterol(),
				request.targetPotassium())) {
			throw new BadRequestException("Beslenme hedefleri negatif olamaz!");
		}

		if (request.targetCalories() != null) {
			program.setTargetCalories(request.targetCalories());
		}
		if (request.targetProtein() != null) {
			program.setTargetProtein(request.targetProtein());
		}
		if (request.targetCarbs() != null) {
			program.setTargetCarbs(request.targetCarbs());
		}
		if (request.targetFat() != null) {
			program.setTargetFat(request.targetFat());
		}
		if (request.targetSugar() != null) {
			program.setTargetSugar(request.targetSugar());
		}
		if (request.targetFiber() != null) {
			program.setTargetFiber(request.targetFiber());
		}
		if (request.targetSodium() != null) {
			program.setTargetSodium(request.targetSodium());
		}
		if (request.targetCholesterol() != null) {
			program.setTargetCholesterol(request.targetCholesterol());
		}
		if (request.targetPotassium() != null) {
			program.setTargetPotassium(request.targetPotassium());
		}

		program.onUpdate(clock.instant());
		DietProgram saved = programRepository.save(program);
		auditLogService.log("DIET_GOALS_UPDATED", currentUser.getEmail(), "Diyet hedefleri güncellendi.");
		handleSyncAndNotification(saved);
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse renameProgram(Long id, String name) {
		if (name == null || name.isBlank()) {
			throw new BadRequestException("Program adı boş olamaz.");
		}
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));
		AppUser currentUser = userContextService.getCurrentUser();
		validateOwnershipAndModifiability(program, currentUser);

		program.setName(name.trim());
		program.onUpdate(clock.instant());
		DietProgram saved = programRepository.save(program);
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	/**
	 * Diyet programını siler. Program sahibi (sporcu) veya programı atayan antrenör
	 * (coach) silebilir. Silme yetki kontrolü içerir.
	 * @param id Silinecek programın benzersiz kimliği
	 */
	@Transactional
	public void deleteProgram(Long id) {
		// İşlemi gerçekleştiren aktif kullanıcı alınır.
		AppUser currentUser = userContextService.getCurrentUser();

		// Silinmek istenen program veritabanından sorgulanır.
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		// İşlemi yapan kişinin programın sahibi (sporcu) olup olmadığı kontrol edilir.
		boolean isOwner = program.getOwner().getId().equals(currentUser.getId());

		// İşlemi yapan kişinin programı atayan koç (COACH) olup olmadığı kontrol edilir.
		boolean isCoach = currentUser.getRole() == com.gym.v2.auth.entity.UserRole.COACH && program.getCoach() != null
				&& program.getCoach().getId().equals(currentUser.getId());

		// Eğer kişi ne sahibi ne de atayan koç ise silme yetkisi yoktur.
		if (!isOwner && !isCoach) {
			throw new BadRequestException("Bu programı silme yetkiniz yok!");
		}

		if (program.isTemplate()) {
			// Şablon ise: tüm atama kopyalarını bul ve sil (zincirleme)
			List<DietProgram> assignedPrograms = programRepository.findByOriginalTemplateId(id);
			for (DietProgram assigned : assignedPrograms) {
				programRepository.delete(assigned);
				if (assigned.getOwner() != null) {
					messagingTemplate.convertAndSend("/topic/diet/" + assigned.getOwner().getId(), "REFRESH_REQUIRED");
				}
			}
			programRepository.delete(program);
		}
		else {
			programRepository.delete(program);
		}

		// İşlem audit log tablosuna kaydedilir.
		auditLogService.log("DIET_PROGRAM_DELETED", currentUser.getEmail(), "Diyet programı silindi. ID: " + id);
	}

	@Transactional
	public DietProgramResponse copyProgram(Long id, String newName) {
		DietProgram original = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Kopyalanacak program bulunamadı."));

		AppUser currentUser = userContextService.getCurrentUser();
		validateOwnershipAndModifiability(original, currentUser);

		DietProgram copy = new DietProgram(currentUser, newName, DietSource.CLIENT);
		copy.setMain(false);
		copy.onPersist(clock.instant());
		copy.setTargetCalories(original.getTargetCalories());
		copy.setTargetProtein(original.getTargetProtein());
		copy.setTargetCarbs(original.getTargetCarbs());
		copy.setTargetFat(original.getTargetFat());
		copy.setTargetSugar(original.getTargetSugar());
		copy.setTargetFiber(original.getTargetFiber());
		copy.setTargetSodium(original.getTargetSodium());
		copy.setTargetCholesterol(original.getTargetCholesterol());
		copy.setTargetPotassium(original.getTargetPotassium());

		for (DietDay day : original.getDietDays()) {
			DietDay newDay = new DietDay(copy, day.getDayOrder(), day.getName());
			for (Meal meal : day.getMeals()) {
				Meal newMeal = new Meal(newDay, meal.getMealType(), meal.getOrderIndex());
				for (MealIngredient ing : meal.getIngredients()) {
					MealIngredient newIng = new MealIngredient();
					newIng.setMeal(newMeal);
					newIng.setFood(ing.getFood());
					newIng.setRecipe(ing.getRecipe());
					newIng.setAmount(ing.getAmount());
					newIng.setNote(ing.getNote());
					newIng.setIgnoreOverride(ing.isIgnoreOverride());
					newMeal.getIngredients().add(newIng);
				}
				newDay.getMeals().add(newMeal);
			}
			copy.getDietDays().add(newDay);
		}

		DietProgram saved = programRepository.save(copy);
		auditLogService.log("DIET_PROGRAM_COPIED", currentUser.getEmail(), "Diyet programı kopyalandı.");
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	public void validateOwnershipAndModifiability(DietProgram program, AppUser currentUser) {
		boolean isOwner = program.getOwner().getId().equals(currentUser.getId());
		boolean isCoachOfProgram = program.getCoach() != null && program.getCoach().getId().equals(currentUser.getId());

		if (!isOwner && !isCoachOfProgram) {
			throw new BadRequestException("Bu diyet programına erişim yetkiniz yok!");
		}

		// Antrenör kaynaklı program yalnızca onu hazırlayan koç tarafından
		// düzenlenebilir.
		// Yasak yalnızca programı alan sporcu (CLIENT) için geçerlidir; koçun kendi
		// programı (owner=koç, coach=null) düzenlenebilir kalmalıdır.
		if (DietSource.COACH == program.getSource()
				&& currentUser.getRole() == com.gym.v2.auth.entity.UserRole.CLIENT) {
			throw new BadRequestException("Antrenör tarafından hazırlanan programlarda değişiklik yapılamaz!");
		}
	}

	/**
	 * Yeni programın/şablonun hedeflerini içinde TUTARLI bir varsayılanla başlatır.
	 * Makrolar tam sayı gram; kalori ise bu makroların GERÇEK kalori toplamıdır: 150g
	 * protein + 200g karb + 67g yağ = 600 + 800 + 603 = 2003 kcal. Kalori = makro
	 * kalorisi olduğu için yüzdeler tam olarak %100'e toplanır; yuvarlama/tutarsızlık
	 * hatası oluşmaz. Kullanıcı hedefi değiştirince karta yansır.
	 */
	public void setDefaultGoals(DietProgram program) {
		program.setTargetCalories(new BigDecimal("2003"));
		program.setTargetProtein(new BigDecimal("150"));
		program.setTargetCarbs(new BigDecimal("200"));
		program.setTargetFat(new BigDecimal("67"));
		program.setTargetSugar(new BigDecimal("50"));
		program.setTargetFiber(new BigDecimal("30"));
		program.setTargetSodium(new BigDecimal("2300"));
		program.setTargetCholesterol(new BigDecimal("300"));
		program.setTargetPotassium(new BigDecimal("3500"));
	}

	private boolean isAnyNegative(BigDecimal... values) {
		for (BigDecimal v : values) {
			if (v != null && v.compareTo(BigDecimal.ZERO) < 0) {
				return true;
			}
		}
		return false;
	}

	private void handleSyncAndNotification(DietProgram program) {
		if (program.isTemplate()) {
			eventPublisher.publishEvent(new DietTemplateUpdatedEvent(program.getId()));
		}
		else if (program.getOwner() != null) {
			AppUser currentUser = userContextService.getCurrentUser();
			// Sadece güncellemeyi yapan kişi sporcunun kendisi değilse WebSocket
			// tetiklenir
			if (!program.getOwner().getId().equals(currentUser.getId())) {
				messagingTemplate.convertAndSend("/topic/diet/" + program.getOwner().getId(), "REFRESH_REQUIRED");
			}
		}
	}

	@Transactional
	public DietProgramResponse approveOrphanedDietProgram(Long id, boolean keep) {
		DietProgram program = programRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Diyet programı bulunamadı: " + id));

		AppUser currentUser = userContextService.getCurrentUser();
		if (!program.getOwner().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu program üzerinde işlem yapma yetkiniz yok.");
		}

		if (keep) {
			program.setCoach(null);
			program.setSource(DietSource.CLIENT);
			// Şablon bağı da koparılır. Aksi hâlde program sporcunun olmasına rağmen eski
			// koçun şablonuna bağlı kalır: koç şablonu düzenlerse içeriği ezilir,
			// silerse program da silinir. Antrenman tarafındaki eşdeğeri
			// (TrainingBlockService.approveOrphanedProgram) bunu zaten yapıyor.
			program.setOriginalTemplateId(null);
			program.onUpdate(clock.instant());
			DietProgram saved = programRepository.save(program);
			return nutritionMapper.toProgramResponse(saved, currentUser.getId());
		}
		else {
			deleteProgram(id);
			return null;
		}
	}

}
