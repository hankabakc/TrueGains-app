package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.security.service.AuditLogService;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.core.service.TransactionalEvents;
import com.gym.v2.nutrition.entity.DietProgram;
import com.gym.v2.nutrition.event.DietTemplateUpdatedEvent;
import com.gym.v2.nutrition.repository.DietProgramRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * G-90: Diyet şablonu bildirimlerinin commit sonrası gönderilmesini doğrulayan testler.
 */
@ExtendWith(MockitoExtension.class)
class DietTemplateServiceNotificationTest {

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

	private DietProgram template;

	private DietProgram copy;

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

		coach = userWithId(2L, "koc@test.com", UserRole.COACH);
		client = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);

		template = new DietProgram();
		template.setId(20L);
		template.setName("Test Sablon");
		template.setOwner(coach);
		template.setTemplate(true);
		template.setDietDays(new ArrayList<>());

		copy = new DietProgram();
		copy.setId(100L);
		copy.setName("Test Sablon Kopyasi");
		copy.setOwner(client);
		copy.setTemplate(false);
		copy.setOriginalTemplateId(20L);
		copy.setDietDays(new ArrayList<>());
	}

	private void currentUserIs(AppUser user) {
		when(userContextService.getCurrentUser()).thenReturn(user);
	}

	@Test
	void assign_notifiesClientOnlyAfterCommit() {
		currentUserIs(coach);
		when(programRepository.findById(20L)).thenReturn(Optional.of(template));

		ClientEntity clientEntity = new ClientEntity();
		clientEntity.setUser(client);
		clientEntity.setCoachId(2L);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientEntity));
		when(programRepository.existsByOwnerIdAndOriginalTemplateId(1L, 20L)).thenReturn(false);
		when(programRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

		TransactionSynchronizationManager.initSynchronization();
		try {
			service.assignTemplateToClient(20L, 1L);
			verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
			TransactionSynchronizationManager.getSynchronizations().forEach(TransactionSynchronization::afterCommit);
			verify(messagingTemplate).convertAndSend("/topic/diet/1", "REFRESH_REQUIRED");
		}
		finally {
			TransactionSynchronizationManager.clearSynchronization();
		}
	}

	@Test
	void unassign_notifiesClientOnlyAfterCommit() {
		currentUserIs(coach);
		when(programRepository.findById(20L)).thenReturn(Optional.of(template));
		when(programRepository.findByOriginalTemplateId(20L)).thenReturn(List.of(copy));

		TransactionSynchronizationManager.initSynchronization();
		try {
			service.unassignTemplate(20L, 1L);
			verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
			TransactionSynchronizationManager.getSynchronizations().forEach(TransactionSynchronization::afterCommit);
			verify(messagingTemplate).convertAndSend("/topic/diet/1", "REFRESH_REQUIRED");
		}
		finally {
			TransactionSynchronizationManager.clearSynchronization();
		}
	}

	@Test
	void templateSync_notifiesEachCopyOnlyAfterCommit() {
		when(programRepository.findById(20L)).thenReturn(Optional.of(template));
		when(programRepository.findByOriginalTemplateId(20L)).thenReturn(List.of(copy));

		TransactionSynchronizationManager.initSynchronization();
		try {
			service.syncTemplateUpdatesToAssignments(new DietTemplateUpdatedEvent(20L));
			verify(messagingTemplate, never()).convertAndSend(anyString(), any(Object.class));
			TransactionSynchronizationManager.getSynchronizations().forEach(TransactionSynchronization::afterCommit);
			verify(messagingTemplate).convertAndSend("/topic/diet/1", "REFRESH_REQUIRED");
		}
		finally {
			TransactionSynchronizationManager.clearSynchronization();
		}
	}

}
