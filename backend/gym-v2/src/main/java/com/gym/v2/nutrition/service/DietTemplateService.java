package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.DietAssignmentResponse;
import com.gym.v2.nutrition.dto.DietProgramResponse;
import com.gym.v2.nutrition.entity.*;
import com.gym.v2.nutrition.event.DietTemplateUpdatedEvent;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * DietTemplateService - Manages Coach templates and template assignment. Implements "Deep
 * Copy" logic with Transactional safety.
 */
@Service
public class DietTemplateService {

	private final DietProgramRepository programRepository;

	private final DietProgramService programService;

	private final UserContextService userContextService;

	private final ClientRepository clientRepository;

	private final NutritionMapper nutritionMapper;

	private final AuditLogService auditLogService;

	private final Clock clock;

	private final SimpMessagingTemplate messagingTemplate;

	public DietTemplateService(DietProgramRepository programRepository, DietProgramService programService,
			UserContextService userContextService, ClientRepository clientRepository, NutritionMapper nutritionMapper,
			AuditLogService auditLogService, Clock clock, SimpMessagingTemplate messagingTemplate) {
		this.programRepository = programRepository;
		this.programService = programService;
		this.userContextService = userContextService;
		this.clientRepository = clientRepository;
		this.nutritionMapper = nutritionMapper;
		this.auditLogService = auditLogService;
		this.clock = clock;
		this.messagingTemplate = messagingTemplate;
	}

	@Transactional(readOnly = true)
	public List<DietProgramResponse> getCoachTemplates() {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Şablonları sadece antrenörler görüntüleyebilir!");
		}
		List<DietProgram> templates = programRepository
			.findByOwnerIdAndTemplateTrueOrderByCreatedAtDesc(currentUser.getId());
		return templates.stream().map(p -> nutritionMapper.toProgramResponse(p, currentUser.getId())).toList();
	}

	@Transactional
	public DietProgramResponse createTemplate(String name) {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Şablonları sadece antrenörler oluşturabilir!");
		}

		DietProgram template = new DietProgram(currentUser, name, DietSource.COACH);
		template.setTemplate(true);
		template.setMain(false);
		template.onPersist(clock.instant());

		programService.setDefaultGoals(template);

		for (int i = 1; i <= 7; i++) {
			DietDay dietDay = new DietDay(template, i, "Gün " + i);
			dietDay.getMeals().add(new Meal(dietDay, MealType.KAHVALTI, 0));
			dietDay.getMeals().add(new Meal(dietDay, MealType.OGLE_YEMEGI, 1));
			dietDay.getMeals().add(new Meal(dietDay, MealType.AKSAM_YEMEGI, 2));
			dietDay.getMeals().add(new Meal(dietDay, MealType.OTHER, 3));
			template.getDietDays().add(dietDay);
		}

		DietProgram saved = programRepository.save(template);
		auditLogService.log("DIET_TEMPLATE_CREATED", currentUser.getEmail(), "Yeni diyet şablonu oluşturuldu: " + name);
		return nutritionMapper.toProgramResponse(saved, currentUser.getId());
	}

	@Transactional
	public DietProgramResponse assignTemplateToClient(Long templateId, Long clientId) {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atama işlemini sadece antrenörler yapabilir!");
		}

		DietProgram template = programRepository.findById(templateId)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı: " + templateId));

		if (!template.isTemplate() || !template.getOwner().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Geçersiz şablon veya erişim yetkisi yok!");
		}

		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Öğrenci bulunamadı: " + clientId));

		if (client.getCoachId() == null || !client.getCoachId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu öğrenci size atanmamış!");
		}

		AppUser clientUser = client.getUser();

		// Mükerrer Atama Kontrolü
		if (programRepository.existsByOwnerIdAndOriginalTemplateId(clientUser.getId(), template.getId())) {
			throw new BadRequestException("Bu şablon daha önce bu öğrenciye atanmış!");
		}

		// Derin kopya (Deep Copy) oluştur
		DietProgram copy = new DietProgram(clientUser, template.getName(), DietSource.COACH);
		copy.setCoach(currentUser);
		copy.setMain(false);
		copy.setTemplate(false);
		copy.setOriginalTemplateId(template.getId());
		copy.onPersist(clock.instant());

		copy.setTargetCalories(template.getTargetCalories());
		copy.setTargetProtein(template.getTargetProtein());
		copy.setTargetCarbs(template.getTargetCarbs());
		copy.setTargetFat(template.getTargetFat());
		copy.setTargetSugar(template.getTargetSugar());
		copy.setTargetFiber(template.getTargetFiber());
		copy.setTargetSodium(template.getTargetSodium());
		copy.setTargetCholesterol(template.getTargetCholesterol());
		copy.setTargetPotassium(template.getTargetPotassium());

		for (DietDay day : template.getDietDays()) {
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
		auditLogService.log("DIET_TEMPLATE_ASSIGNED", currentUser.getEmail(), "Diyet şablonu öğrenciye atandı. Şablon: "
				+ template.getName() + ", Öğrenci: " + clientUser.getEmail());

		// WebSocket üzerinden sporcuya bildirim gönderilir
		messagingTemplate.convertAndSend("/topic/diet/" + clientUser.getId(), "REFRESH_REQUIRED");

		return nutritionMapper.toProgramResponse(saved, clientUser.getId());
	}

	@Transactional(readOnly = true)
	public List<DietAssignmentResponse> getTemplateAssignments(Long templateId) {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atamaları sadece antrenörler görüntüleyebilir!");
		}

		DietProgram template = programRepository.findById(templateId)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı: " + templateId));

		if (!template.isTemplate() || !template.getOwner().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Geçersiz şablon veya erişim yetkisi yok!");
		}

		return toAssignmentResponses(programRepository.findByOriginalTemplateId(templateId));
	}

	@Transactional
	public void unassignTemplate(Long templateId, Long clientId) {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atamayı sadece antrenörler kaldırabilir!");
		}

		DietProgram template = programRepository.findById(templateId)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı: " + templateId));

		if (!template.isTemplate() || !template.getOwner().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Geçersiz şablon veya erişim yetkisi yok!");
		}

		List<DietProgram> assigned = programRepository.findByOriginalTemplateId(templateId);
		DietProgram assignedProgram = assigned.stream()
			.filter(prog -> prog.getOwner().getId().equals(clientId))
			.findFirst()
			.orElseThrow(() -> new NotFoundException("Bu öğrenciye atanmış bir program kopyası bulunamadı!"));

		programRepository.delete(assignedProgram);

		auditLogService.log("DIET_TEMPLATE_UNASSIGNED", currentUser.getEmail(),
				"Diyet şablon ataması kaldırıldı. Şablon: " + template.getName() + ", Öğrenci ID: " + clientId);

		// WebSocket ile sporcunun ekranını yenilet
		messagingTemplate.convertAndSend("/topic/diet/" + clientId, "REFRESH_REQUIRED");
	}

	@Transactional(readOnly = true)
	public List<DietAssignmentResponse> getCoachAssignments() {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atamaları sadece antrenörler görüntüleyebilir!");
		}

		return toAssignmentResponses(programRepository.findByCoachIdAndTemplateFalse(currentUser.getId()));
	}

	/**
	 * Antrenörün yetkili olduğu sporcunun (öğrencinin) aktif diyet programı atamasını
	 * getirir.
	 * @param clientId Bilgisi istenecek sporcunun ID'si
	 * @return DietAssignmentResponse Diyet programı atama bilgisi
	 */
	@Transactional(readOnly = true)
	public DietAssignmentResponse getClientAssignmentForCoach(Long clientId) {
		// İşlemi yapan güncel koç kullanıcısı alınır.
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Atamaları sadece antrenörler görüntüleyebilir!");
		}

		// Bilgileri istenen sporcu ve koç ilişkisi doğrulanır.
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Öğrenci bulunamadı: " + clientId));

		if (client.getCoachId() == null || !client.getCoachId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu öğrenci size atanmamış!");
		}

		// Koçun bu sporcuya atamış olduğu aktif (isTemplate = false) diyet programı kopya
		// kaydı aranır.
		List<DietProgram> assignedPrograms = programRepository.findByCoachIdAndTemplateFalse(currentUser.getId());
		DietProgram prog = assignedPrograms.stream()
			.filter(p -> p.getOwner().getId().equals(clientId))
			.findFirst()
			.orElseThrow(() -> new NotFoundException("Bu sporcuya atanmış aktif bir diyet programı bulunamadı!"));

		return nutritionMapper.toAssignmentResponse(prog, client);
	}

	/**
	 * Şablonun gün/öğün yapısını atanmış bir kopyaya <b>yerinde</b> uygular.
	 * <p>
	 * Daha önce burada {@code copy.getDietDays().clear()} vardı. {@code DietProgram},
	 * {@code DietDay} ve {@code Meal} ilişkilerinin hepsi
	 * {@code cascade = ALL, orphanRemoval = true} olduğu için bu çağrı sporcunun gün,
	 * öğün ve malzeme satırlarını <b>veritabanından siliyordu</b>. Öğünler yeniden
	 * yaratıldığında kimlikleri değiştiği için {@code meal_entry.planned_meal_id} —
	 * yabancı anahtar kısıtı olmayan yumuşak bir referans — var olmayan satırlara işaret
	 * eder hâle geliyor, "planlanan öğün yendi mi" bilgisi sessizce kayboluyordu.
	 * </p>
	 * <p>
	 * Eşleştirme konuma göre: günler {@code dayOrder}, öğünler {@code orderIndex}
	 * üzerinden. Şablonda artık bulunmayan gün/öğün silinir, yeni eklenen oluşturulur,
	 * kalanlar yerinde güncellenir. Malzemeler her hâlükârda yenilenir — onlara dışarıdan
	 * referans veren bir tablo yok.
	 * </p>
	 */
	private void syncDays(DietProgram template, DietProgram copy) {
		Set<Integer> templateDayOrders = template.getDietDays()
			.stream()
			.map(DietDay::getDayOrder)
			.collect(Collectors.toSet());
		copy.getDietDays().removeIf(day -> !templateDayOrders.contains(day.getDayOrder()));

		Map<Integer, DietDay> copyDaysByOrder = copy.getDietDays()
			.stream()
			.collect(Collectors.toMap(DietDay::getDayOrder, day -> day, (first, second) -> first));

		for (DietDay templateDay : template.getDietDays()) {
			DietDay copyDay = copyDaysByOrder.get(templateDay.getDayOrder());
			if (copyDay == null) {
				copyDay = new DietDay(copy, templateDay.getDayOrder(), templateDay.getName());
				copy.getDietDays().add(copyDay);
			}
			else {
				copyDay.setName(templateDay.getName());
			}
			syncMeals(templateDay, copyDay);
		}
	}

	private void syncMeals(DietDay templateDay, DietDay copyDay) {
		Set<Integer> templateMealOrders = templateDay.getMeals()
			.stream()
			.map(Meal::getOrderIndex)
			.collect(Collectors.toSet());
		copyDay.getMeals().removeIf(meal -> !templateMealOrders.contains(meal.getOrderIndex()));

		Map<Integer, Meal> copyMealsByOrder = copyDay.getMeals()
			.stream()
			.collect(Collectors.toMap(Meal::getOrderIndex, meal -> meal, (first, second) -> first));

		for (Meal templateMeal : templateDay.getMeals()) {
			Meal copyMeal = copyMealsByOrder.get(templateMeal.getOrderIndex());
			if (copyMeal == null) {
				copyMeal = new Meal(copyDay, templateMeal.getMealType(), templateMeal.getOrderIndex());
				copyDay.getMeals().add(copyMeal);
			}
			else {
				copyMeal.setMealType(templateMeal.getMealType());
			}
			copyIngredients(templateMeal, copyMeal);
		}
	}

	private void copyIngredients(Meal templateMeal, Meal copyMeal) {
		copyMeal.getIngredients().clear();
		for (MealIngredient ing : templateMeal.getIngredients()) {
			MealIngredient newIng = new MealIngredient();
			newIng.setMeal(copyMeal);
			newIng.setFood(ing.getFood());
			newIng.setRecipe(ing.getRecipe());
			newIng.setAmount(ing.getAmount());
			newIng.setNote(ing.getNote());
			newIng.setIgnoreOverride(ing.isIgnoreOverride());
			copyMeal.getIngredients().add(newIng);
		}
	}

	@EventListener
	@Transactional
	public void syncTemplateUpdatesToAssignments(DietTemplateUpdatedEvent event) {
		Long templateId = event.templateId();
		DietProgram template = programRepository.findById(templateId)
			.orElseThrow(() -> new NotFoundException("Şablon bulunamadı: " + templateId));

		List<DietProgram> assignedPrograms = programRepository.findByOriginalTemplateId(templateId);

		for (DietProgram copy : assignedPrograms) {
			copy.setTargetCalories(template.getTargetCalories());
			copy.setTargetProtein(template.getTargetProtein());
			copy.setTargetCarbs(template.getTargetCarbs());
			copy.setTargetFat(template.getTargetFat());
			copy.setTargetSugar(template.getTargetSugar());
			copy.setTargetFiber(template.getTargetFiber());
			copy.setTargetSodium(template.getTargetSodium());
			copy.setTargetCholesterol(template.getTargetCholesterol());
			copy.setTargetPotassium(template.getTargetPotassium());

			syncDays(template, copy);

			programRepository.save(copy);

			if (copy.getOwner() != null) {
				messagingTemplate.convertAndSend("/topic/diet/" + copy.getOwner().getId(), "REFRESH_REQUIRED");
			}
		}
	}

	/**
	 * Atama listelerini sporcu profilleriyle birlikte, <b>tek</b> profil sorgusuyla
	 * üretir.
	 * <p>
	 * Daha önce her atama için ayrı {@code findByUserId} çağrılıyordu: 40 öğrencisi olan
	 * koçun ekranı 41 sorgu yapıyordu. Aynı desenin düzeltilmiş hâli
	 * {@code ChatService.getMyConversations}'ta zaten vardı.
	 * </p>
	 */
	private List<DietAssignmentResponse> toAssignmentResponses(List<DietProgram> programs) {
		if (programs.isEmpty()) {
			return List.of();
		}
		List<Long> ownerIds = programs.stream().map(prog -> prog.getOwner().getId()).distinct().toList();
		Map<Long, ClientEntity> profilesByUserId = clientRepository.findAllByUserIdIn(ownerIds)
			.stream()
			.collect(Collectors.toMap(ClientEntity::getUserId, profile -> profile, (first, second) -> first));

		return programs.stream()
			.map(prog -> nutritionMapper.toAssignmentResponse(prog, profilesByUserId.get(prog.getOwner().getId())))
			.toList();
	}

}
