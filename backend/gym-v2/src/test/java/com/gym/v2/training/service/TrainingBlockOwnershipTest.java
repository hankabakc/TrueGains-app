package com.gym.v2.training.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.service.NotificationService;
import com.gym.v2.training.dto.TrainingBlockDTO;
import com.gym.v2.training.entity.TrainingBlock;
import com.gym.v2.training.repository.ExerciseRepository;
import com.gym.v2.training.repository.TrainingBlockRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code TrainingBlockService} sahiplik (IDOR) sınırları.
 * <p>
 * Program ve şablon kimlikleri URL'den geldiği için erişim tamamen servis katmanındaki
 * sahiplik kontrolüne bağlıdır. Burada test edilen soru: <b>başkasının programına
 * dokunulabiliyor mu?</b>
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class TrainingBlockOwnershipTest {

	@Mock
	private TrainingBlockRepository blockRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private ExerciseRepository exerciseRepository;

	@Mock
	private TrainingMapper trainingMapper;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	@Mock
	private NotificationService notificationService;

	private TrainingBlockService service;

	private MockedStatic<SecurityUtils> securityUtils;

	/** Programın sahibi sporcu. */
	private AppUser owner;

	/** Programı atayan koç. */
	private AppUser assignedCoach;

	/** İlgisiz bir koç. */
	private AppUser otherCoach;

	/** İlgisiz bir sporcu. */
	private AppUser otherClient;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new TrainingBlockService(blockRepository, clientRepository, userRepository, exerciseRepository,
				trainingMapper, messagingTemplate, notificationService,
				new com.gym.v2.core.service.TransactionalEvents(), fixedClock);

		owner = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		assignedCoach = userWithId(2L, "koc@test.com", UserRole.COACH);
		otherCoach = userWithId(77L, "baska.koc@test.com", UserRole.COACH);
		otherClient = userWithId(99L, "baska.sporcu@test.com", UserRole.CLIENT);

		securityUtils = Mockito.mockStatic(SecurityUtils.class);
	}

	@AfterEach
	void tearDown() {
		securityUtils.close();
	}

	private void currentUserIs(AppUser user) {
		securityUtils.when(SecurityUtils::getCurrentUserEmail).thenReturn(user.getEmail());
		when(userRepository.findByEmail(user.getEmail())).thenReturn(Optional.of(user));
	}

	/** Sahibi sporcu 1, atayan koçu 2 olan kişisel program. */
	private TrainingBlock personalProgram() {
		TrainingBlock block = new TrainingBlock("Program", "Aciklama", assignedCoach, owner, LocalDate.now(),
				LocalDate.now().plusWeeks(4));
		ReflectionTestUtils.setField(block, "id", 10L);
		return block;
	}

	/** Koç 2'ye ait şablon. */
	private TrainingBlock coachTemplate() {
		TrainingBlock block = new TrainingBlock("Sablon", "Aciklama", assignedCoach, null, LocalDate.now(),
				LocalDate.now().plusWeeks(4));
		ReflectionTestUtils.setField(block, "id", 20L);
		block.setIsTemplate(true);
		return block;
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setCoachId(coachId);
		return entity;
	}

	private TrainingBlockDTO requestDto() {
		return new TrainingBlockDTO(null, "Yeni Ad", "Yeni Aciklama", null, null, null, null, LocalDate.now(), null,
				null, 4, null, null, null, null);
	}

	// ---------------------------------------------------------------------------
	// deletePersonalProgram — sahibi sporcu veya sporcunun koçu
	// ---------------------------------------------------------------------------

	@Test
	void deletePersonalProgram_anotherClient_isRejectedAndDeletesNothing() {
		currentUserIs(otherClient);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));

		assertThatThrownBy(() -> service.deletePersonalProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).delete(any());
	}

	@Test
	void deletePersonalProgram_coachOfSomeoneElse_isRejectedAndDeletesNothing() {
		currentUserIs(otherCoach);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));
		// Sporcu 1, koç 2'ye bağlı; sorgulayan koç 77.
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));

		assertThatThrownBy(() -> service.deletePersonalProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).delete(any());
	}

	@Test
	void deletePersonalProgram_owner_deletes() {
		TrainingBlock block = personalProgram();
		currentUserIs(owner);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(block));

		service.deletePersonalProgram(10L);

		verify(blockRepository).delete(block);
	}

	@Test
	void deletePersonalProgram_assignedCoach_deletes() {
		TrainingBlock block = personalProgram();
		currentUserIs(assignedCoach);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(block));

		service.deletePersonalProgram(10L);

		verify(blockRepository).delete(block);
	}

	// ---------------------------------------------------------------------------
	// createCoachTemplate — yalnızca koç rolü
	// ---------------------------------------------------------------------------

	@Test
	void createCoachTemplate_clientRole_isRejectedAndSavesNothing() {
		currentUserIs(owner);

		assertThatThrownBy(() -> service.createCoachTemplate(requestDto())).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).saveAndFlush(any());
	}

	// ---------------------------------------------------------------------------
	// updateCoachTemplate / deleteCoachTemplate — yalnızca şablonu yaratan koç
	// ---------------------------------------------------------------------------

	@Test
	void updateCoachTemplate_anotherCoach_isRejectedAndTouchesNoAssignedProgram() {
		currentUserIs(otherCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));

		assertThatThrownBy(() -> service.updateCoachTemplate(20L, requestDto()))
			.isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).saveAndFlush(any());
		// Şablon güncellemesi ona bağlı tüm sporcu programlarına yayılır; yabancı koç
		// bu zinciri hiç başlatamamalı.
		verify(blockRepository, never()).findAssignedBlocksByTemplateId(any());
	}

	@Test
	void updateCoachTemplate_ownProgramButNotATemplate_isRejected() {
		// Şablon uç noktası kişisel programlar üzerinde çalışmamalı.
		currentUserIs(assignedCoach);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));

		assertThatThrownBy(() -> service.updateCoachTemplate(10L, requestDto()))
			.isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).saveAndFlush(any());
	}

	@Test
	void deleteCoachTemplate_anotherCoach_isRejectedAndDeletesNothing() {
		currentUserIs(otherCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));

		assertThatThrownBy(() -> service.deleteCoachTemplate(20L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).delete(any());
	}

	// ---------------------------------------------------------------------------
	// assignTemplateToClient — kendi şablonunu, yalnızca kendi öğrencine
	// ---------------------------------------------------------------------------

	@Test
	void assignTemplateToClient_templateOfAnotherCoach_isRejectedAndAssignsNothing() {
		// Atama şablonun tüm gün ve egzersizlerini kopyalayıp yanıtta döndürür; koruma
		// olmazsa bu, başka bir koçun program içeriğinin okunması demektir.
		currentUserIs(otherCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).save(any());
		verify(notificationService, never()).sendPushNotification(any(), any(), any());
	}

	@Test
	void assignTemplateToClient_clientOfAnotherCoach_isRejectedAndAssignsNothing() {
		currentUserIs(assignedCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));
		// Sporcu 1, koç 77'ye bağlı; atamayı koç 2 deniyor.
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(77L)));

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).save(any());
		verify(notificationService, never()).sendPushNotification(any(), any(), any());
	}

	@Test
	void assignTemplateToClient_clientWithoutCoach_isRejected() {
		currentUserIs(assignedCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(null)));

		assertThatThrownBy(() -> service.assignTemplateToClient(20L, 1L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).save(any());
	}

	@Test
	void assignTemplateToClient_ownTemplateToOwnClient_assigns() {
		currentUserIs(assignedCoach);
		when(blockRepository.findById(20L)).thenReturn(Optional.of(coachTemplate()));
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(userRepository.findById(1L)).thenReturn(Optional.of(owner));

		service.assignTemplateToClient(20L, 1L);

		verify(blockRepository).save(any());
	}

	// ---------------------------------------------------------------------------
	// activateProgram — yalnızca programın atandığı sporcu
	// ---------------------------------------------------------------------------

	@Test
	void activateProgram_anotherClient_isRejectedAndChangesNoProgram() {
		currentUserIs(otherClient);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));

		assertThatThrownBy(() -> service.activateProgram(10L)).isInstanceOf(BadRequestException.class);

		// Reddedilen çağrı yabancı sporcunun kendi programlarını da pasifleştirmemeli.
		verify(blockRepository, never()).findByClientId(any());
		verify(blockRepository, never()).saveAndFlush(any());
	}

	@Test
	void activateProgram_assignedCoach_isRejected() {
		// Hangi programın aktif olduğu sporcunun kararıdır; koç zorlayamaz.
		currentUserIs(assignedCoach);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));

		assertThatThrownBy(() -> service.activateProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).saveAndFlush(any());
	}

	@Test
	void activateProgram_owner_activatesAndDeactivatesTheOthers() {
		TrainingBlock block = personalProgram();
		TrainingBlock previous = personalProgram();
		ReflectionTestUtils.setField(previous, "id", 11L);
		previous.setIsActive(true);

		currentUserIs(owner);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(block));
		when(blockRepository.findByClientId(1L)).thenReturn(List.of(previous));

		service.activateProgram(10L);

		assertThat(block.getIsActive()).isTrue();
		assertThat(previous.getIsActive()).isFalse();
	}

	// ---------------------------------------------------------------------------
	// approveOrphanedProgram — yalnızca programın sahibi sporcu
	// ---------------------------------------------------------------------------

	@Test
	void approveOrphanedProgram_notTheOwner_isRejectedAndChangesNothing() {
		currentUserIs(otherClient);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(personalProgram()));

		assertThatThrownBy(() -> service.approveOrphanedProgram(10L, true)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).saveAndFlush(any());
		verify(blockRepository, never()).delete(any());
	}

	@Test
	void approveOrphanedProgram_ownerKeeps_detachesCoachAndTemplate() {
		TrainingBlock block = personalProgram();
		block.setTemplateId(20L);
		currentUserIs(owner);
		when(blockRepository.findById(10L)).thenReturn(Optional.of(block));
		when(blockRepository.saveAndFlush(block)).thenReturn(block);

		service.approveOrphanedProgram(10L, true);

		assertThat(block.getCoach()).isNull();
		assertThat(block.getTemplateId()).isNull();
	}

}
