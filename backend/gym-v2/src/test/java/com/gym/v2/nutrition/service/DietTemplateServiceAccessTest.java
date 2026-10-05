package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.ConflictException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.core.service.TransactionalEvents;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * G-91 (KR18): DietTemplateService erişim kontrolü testleri.
 * <p>
 * Yalnızca antrenörlerin yapabileceği şablon işlemleri sporcular için 403
 * (AccessDeniedException), başkasına ait şablon ve öğrenciler için varlık sızdırılmadan
 * 404 (NotFoundException) dönmelidir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class DietTemplateServiceAccessTest {

	@Mock
	private DietProgramRepository programRepository;

	@Mock
	private DietProgramService programService;

	@Mock
	private UserContextService userContextService;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private NutritionMapper nutritionMapper;

	@Mock
	private AuditLogService auditLogService;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	private DietTemplateService service;

	private AppUser coach;

	private AppUser client;

	private AppUser otherCoach;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new DietTemplateService(programRepository, programService, userContextService, clientRepository,
				nutritionMapper, auditLogService, fixedClock, messagingTemplate, new TransactionalEvents());

		client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		coach = userWithId(2L, "koc@test.com", UserRole.COACH);
		otherCoach = userWithId(99L, "baska.koc@test.com", UserRole.COACH);
	}

	private void currentUserIs(AppUser user) {
		when(userContextService.getCurrentUser()).thenReturn(user);
	}

	@Test
	void coachOnlyOperations_byClient_areForbiddenAndTouchNothing() {
		currentUserIs(client);

		assertThatThrownBy(() -> service.getCoachTemplates()).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.createTemplate("x")).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.getTemplateAssignments(20L)).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.unassignTemplate(20L, 1L)).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.getCoachAssignments()).isInstanceOf(AccessDeniedException.class);
		assertThatThrownBy(() -> service.getClientAssignmentForCoach(1L)).isInstanceOf(AccessDeniedException.class);

		verifyNoInteractions(programRepository, clientRepository);
	}

	@Test
	void templateOfAnotherCoachOrNonTemplate_isNotFound() {
		currentUserIs(coach);

		DietProgram templateOfOtherCoach = new DietProgram();
		templateOfOtherCoach.setId(20L);
		templateOfOtherCoach.setOwner(otherCoach);
		templateOfOtherCoach.setTemplate(true);

		DietProgram nonTemplate = new DietProgram();
		nonTemplate.setId(21L);
		nonTemplate.setOwner(coach);
		nonTemplate.setTemplate(false);

		when(programRepository.findById(20L)).thenReturn(Optional.of(templateOfOtherCoach));
		when(programRepository.findById(21L)).thenReturn(Optional.of(nonTemplate));

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Şablon bulunamadı: 20");

		assertThatThrownBy(() -> service.getTemplateAssignments(20L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Şablon bulunamadı: 20");

		assertThatThrownBy(() -> service.unassignTemplate(20L, 1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Şablon bulunamadı: 20");

		assertThatThrownBy(() -> service.getTemplateAssignments(21L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Şablon bulunamadı: 21");

		verify(programRepository, never()).save(any());
		verify(programRepository, never()).delete(any());
	}

	@Test
	void studentOfAnotherCoach_isNotFound() {
		currentUserIs(coach);

		DietProgram ownTemplate = new DietProgram();
		ownTemplate.setId(20L);
		ownTemplate.setOwner(coach);
		ownTemplate.setTemplate(true);
		when(programRepository.findById(20L)).thenReturn(Optional.of(ownTemplate));

		ClientEntity clientOfOtherCoach = new ClientEntity();
		clientOfOtherCoach.setCoachId(99L);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientOfOtherCoach));

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Öğrenci bulunamadı: 1");

		assertThatThrownBy(() -> service.getClientAssignmentForCoach(1L)).isInstanceOf(NotFoundException.class)
			.hasMessage("Öğrenci bulunamadı: 1");

		verify(programRepository, never()).save(any());
	}

	@Test
	void assignSameTemplateTwice_isConflictAndSavesNothing() {
		currentUserIs(coach);

		DietProgram ownTemplate = new DietProgram();
		ownTemplate.setId(20L);
		ownTemplate.setOwner(coach);
		ownTemplate.setTemplate(true);
		when(programRepository.findById(20L)).thenReturn(Optional.of(ownTemplate));

		ClientEntity ownClient = new ClientEntity();
		ownClient.setCoachId(coach.getId());
		ownClient.setUser(client);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(ownClient));

		when(programRepository.existsByOwnerIdAndOriginalTemplateId(client.getId(), 20L)).thenReturn(true);

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(ConflictException.class)
			.hasMessage("Bu şablon daha önce bu öğrenciye atanmış!");

		verify(programRepository, never()).save(any());
	}

}
