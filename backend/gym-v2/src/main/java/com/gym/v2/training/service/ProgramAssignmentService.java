package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.training.dto.AssignedStudentSummaryRecord;
import com.gym.v2.training.dto.ProgramWithAssignmentsRecord;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.repository.TrainingBlockRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.gym.v2.auth.repository.AppUserRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

/**
 * Koçların program atamalarını ve atanan öğrencilerin listelenmesini yöneten iş mantığı
 * servis sınıfı.
 */
@Service
public class ProgramAssignmentService {

	private static final Logger log = LoggerFactory.getLogger(ProgramAssignmentService.class);

	private final TrainingBlockRepository blockRepository;

	private final ClientRepository clientRepository;

	private final TrainingBlockService trainingBlockService;

	private final AppUserRepository userRepository;

	private final SimpMessagingTemplate messagingTemplate;

	private final Clock clock;

	public ProgramAssignmentService(TrainingBlockRepository blockRepository, ClientRepository clientRepository,
			TrainingBlockService trainingBlockService, AppUserRepository userRepository,
			SimpMessagingTemplate messagingTemplate, Clock clock) {
		this.blockRepository = blockRepository;
		this.clientRepository = clientRepository;
		this.trainingBlockService = trainingBlockService;
		this.userRepository = userRepository;
		this.messagingTemplate = messagingTemplate;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public List<ProgramWithAssignmentsRecord> getAssignedPrograms(Long coachId) {
		log.info("[ASSIGNMENT] Koç için atanmış programlar getiriliyor. Coach ID: {}", coachId);
		List<TrainingBlock> templates = this.blockRepository.findByCoachIdAndIsTemplateTrue(coachId);
		List<TrainingBlock> activeAssignments = this.blockRepository.findByCoachIdAndIsTemplateFalse(coachId);
		List<ProgramWithAssignmentsRecord> result = new ArrayList<>();
		java.util.Map<Long, List<AssignedStudentSummaryRecord>> templateGroupMap = new java.util.HashMap<>();

		// Sporcu profilleri ve şablon kimlikleri tek seferde toplanır; daha önce atama
		// başına ayrı findByUserId sorgusu ve atama başına şablon listesinde doğrusal
		// arama yapılıyordu, yani ekranın maliyeti öğrenci sayısıyla büyüyordu.
		List<Long> studentIds = activeAssignments.stream()
			.map(TrainingBlock::getClient)
			.filter(java.util.Objects::nonNull)
			.map(AppUser::getId)
			.distinct()
			.toList();
		java.util.Map<Long, ClientEntity> profilesByUserId = studentIds.isEmpty() ? java.util.Map.of()
				: this.clientRepository.findAllByUserIdIn(studentIds)
					.stream()
					.collect(java.util.stream.Collectors.toMap(ClientEntity::getUserId, profile -> profile,
							(first, second) -> first));
		java.util.Set<Long> templateIds = templates.stream()
			.map(TrainingBlock::getId)
			.collect(java.util.stream.Collectors.toSet());

		for (TrainingBlock copy : activeAssignments) {
			AppUser student = copy.getClient();
			if (student == null) {
				continue;
			}
			ClientEntity profile = profilesByUserId.get(student.getId());
			String fullName = profile != null ? profile.getFullName() : student.getEmail();

			int durationWeeks = copy.getDurationWeeks() != null ? copy.getDurationWeeks() : 4;
			long days = ChronoUnit.DAYS.between(copy.getStartDate(), LocalDate.now(clock));
			int weeksElapsed = days < 0 ? 0 : (int) (days / 7) + 1;
			boolean isActive = copy.getIsActive() != null ? copy.getIsActive() : false;

			AssignedStudentSummaryRecord summary = new AssignedStudentSummaryRecord(student.getId(), fullName,
					profile != null ? profile.getProfilePhotoUrl() : null, copy.getId(), durationWeeks, weeksElapsed,
					isActive);
			Long tId = copy.getTemplateId();
			if (tId != null && templateIds.contains(tId)) {
				templateGroupMap.computeIfAbsent(tId, k -> new ArrayList<>()).add(summary);
			}
		}

		for (TrainingBlock template : templates) {
			List<AssignedStudentSummaryRecord> studentSummaries = templateGroupMap.get(template.getId());
			if (studentSummaries != null && !studentSummaries.isEmpty()) {
				result.add(new ProgramWithAssignmentsRecord(template.getId(), template.getName(),
						template.getDescription(), studentSummaries));
			}
		}
		return result;
	}

	private void deleteAssignedProgramWithFallback(TrainingBlock assignedProgram, Long studentId) {
		this.blockRepository.delete(assignedProgram);
		this.messagingTemplate.convertAndSend("/topic/training/" + studentId, "REFRESH_REQUIRED");
	}

	/**
	 * Bir şablondan atanmış program kopyasını sporcudan kaldırır.
	 * <p>
	 * <b>Silme geri alınamaz ve zincirlemedir:</b> kopya silinince {@code orphanRemoval}
	 * ile günleri ve egzersizleri, onlarla birlikte de {@code workout_logs} kayıtları
	 * ({@code ON DELETE CASCADE}) gider. Yani yanlış programı seçmek, sporcunun yanlış
	 * antrenman geçmişini silmek demektir. Bu yüzden hedef <b>kesin</b> olarak
	 * belirlenmelidir.
	 * </p>
	 * <p>
	 * Kaldırılan iki belirsizlik:
	 * </p>
	 * <ul>
	 * <li><b>İsim bazlı yedek eşleştirme:</b> şablon bağı bulunamadığında program
	 * <i>adına</i> göre arama yapılıyordu. Koçun aynı isimli iki programı varsa yanlış
	 * olan silinirdi.</li>
	 * <li><b>Sırasız {@code findFirst}:</b> birden fazla eşleşmede hangisinin silineceği
	 * veritabanının döndürdüğü sıraya bağlıydı. Artık belirsizlik sessizce çözülmüyor,
	 * hata veriliyor.</li>
	 * </ul>
	 */
	@Transactional
	public void unassignProgramFromStudent(Long coachId, Long programId, Long studentId) {
		List<TrainingBlock> candidates;

		if (programId == -1L) {
			// Şablon belirtilmeden "bu koçun bu sporcuya atadığı programı kaldır".
			candidates = this.blockRepository.findByClientId(studentId)
				.stream()
				.filter(prog -> prog.getCoach() != null && prog.getCoach().getId().equals(coachId)
						&& !Boolean.TRUE.equals(prog.getIsTemplate()))
				.toList();
		}
		else {
			TrainingBlock template = this.blockRepository.findById(programId)
				.orElseThrow(() -> new NotFoundException("Program şablonu bulunamadı."));
			if (template.getCoach() == null || !template.getCoach().getId().equals(coachId)) {
				throw new BadRequestException("Bu program üzerinde işlem yapma yetkiniz yok.");
			}

			candidates = this.blockRepository.findByTemplateIdAndIsTemplateFalse(programId)
				.stream()
				.filter(prog -> prog.getClient() != null && prog.getClient().getId().equals(studentId))
				.toList();
		}

		if (candidates.isEmpty()) {
			throw new NotFoundException("Bu sporcuya atanmış program kopyası bulunamadı.");
		}
		if (candidates.size() > 1) {
			throw new BadRequestException("Bu sporcuya birden fazla program atanmış; "
					+ "hangisinin kaldırılacağı belirsiz. Lütfen listeden tek bir program seçin.");
		}

		deleteAssignedProgramWithFallback(candidates.getFirst(), studentId);
	}

	@Transactional(readOnly = true)
	public List<TrainingBlock> getAssignedProgramsForClient(Long coachId, Long clientId) {
		ClientEntity client = this.clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu kaydı bulunamadı. ID: " + clientId));
		if (!coachId.equals(client.getCoachId())) {
			throw new BadRequestException("Bu sporcu size atanmamış, erişim yetkiniz bulunmuyor.");
		}
		return this.blockRepository.findByClientIdAndIsActiveTrueWithFetch(clientId);
	}

}
