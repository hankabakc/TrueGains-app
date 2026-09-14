package com.gym.v2.training.service;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.training.repository.TrainingBlockRepository;
import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.training.entity.TrainingBlock;
import java.time.LocalDate;
import java.util.List;
import org.springframework.test.util.ReflectionTestUtils;
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

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code ProgramAssignmentService.getAssignedProgramsForClient} sahiplik kontrolü.
 * <p>
 * Hem koç hem sporcu kimliği çağrıya parametre olarak gelir. Koruma olmazsa bir koç,
 * kendisine atanmamış herhangi bir sporcunun antrenman programlarını okuyabilir.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class ProgramAssignmentServiceTest {

	@Mock
	private TrainingBlockRepository blockRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private TrainingBlockService trainingBlockService;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	private ProgramAssignmentService service;

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new ProgramAssignmentService(blockRepository, clientRepository, trainingBlockService, userRepository,
				messagingTemplate, fixedClock);
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setCoachId(coachId);
		return entity;
	}

	@Test
	void getAssignedProgramsForClient_clientNotAssignedToThisCoach_throwsAndReadsNoPrograms() {
		// Sporcu koç 7'ye bağlı; koç 2 sorguluyor.
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(7L)));

		assertThatThrownBy(() -> service.getAssignedProgramsForClient(2L, 50L)).isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).findByClientIdAndIsActiveTrueWithFetch(any());
	}

	@Test
	void getAssignedProgramsForClient_clientWithoutCoach_isRejected() {
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(null)));

		assertThatThrownBy(() -> service.getAssignedProgramsForClient(2L, 50L)).isInstanceOf(BadRequestException.class);
	}

	@Test
	void getAssignedProgramsForClient_unknownClient_throwsNotFound() {
		when(clientRepository.findByUserId(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getAssignedProgramsForClient(2L, 404L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void getAssignedProgramsForClient_ownClient_readsThatClientsPrograms() {
		when(clientRepository.findByUserId(50L)).thenReturn(Optional.of(clientLinkedTo(2L)));

		service.getAssignedProgramsForClient(2L, 50L);

		verify(blockRepository).findByClientIdAndIsActiveTrueWithFetch(50L);
	}

	// ---------------------------------------------------------------------------
	// unassignProgramFromStudent — silme geri alınamaz, hedef kesin olmalı
	// ---------------------------------------------------------------------------

	/**
	 * Kimliği olan bir kullanıcı üretir; {@code AppUser.id} yalnızca JPA tarafından
	 * atanır.
	 */
	private AppUser userWithId(Long id) {
		AppUser user = AppUser.builder().email("u" + id + "@test.com").build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	private TrainingBlock assignedCopy(Long id, Long coachId, Long clientId, String name) {
		TrainingBlock block = new TrainingBlock(name, "Aciklama", userWithId(coachId), userWithId(clientId),
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1));
		block.setId(id);
		block.setIsTemplate(false);
		return block;
	}

	private TrainingBlock templateOf(Long id, Long coachId, String name) {
		TrainingBlock template = new TrainingBlock(name, "Aciklama", userWithId(coachId), null,
				LocalDate.of(2026, 1, 1), LocalDate.of(2026, 2, 1));
		template.setId(id);
		template.setIsTemplate(true);
		return template;
	}

	/**
	 * Silme zincirlemedir: kopya silinince günleri, egzersizleri ve sporcunun
	 * {@code workout_logs} kayıtları da gider. Birden fazla aday varken sessizce birini
	 * seçmek, yanlış geçmişi silmek demektir.
	 */
	@Test
	void unassign_multipleCandidates_isRejectedInsteadOfDeletingAnArbitraryOne() {
		TrainingBlock template = templateOf(100L, 7L, "Push Pull Legs");

		when(blockRepository.findById(100L)).thenReturn(Optional.of(template));
		when(blockRepository.findByTemplateIdAndIsTemplateFalse(100L)).thenReturn(
				List.of(assignedCopy(201L, 7L, 50L, "Push Pull Legs"), assignedCopy(202L, 7L, 50L, "Push Pull Legs")));

		assertThatThrownBy(() -> service.unassignProgramFromStudent(7L, 100L, 50L))
			.isInstanceOf(BadRequestException.class);

		verify(blockRepository, never()).delete(any());
	}

	/** Şablon bağı yoksa isme göre tahmin yürütülmez; hata verilir. */
	@Test
	void unassign_noLinkedCopy_doesNotFallBackToNameMatching() {
		TrainingBlock template = templateOf(100L, 7L, "Push Pull Legs");

		when(blockRepository.findById(100L)).thenReturn(Optional.of(template));
		when(blockRepository.findByTemplateIdAndIsTemplateFalse(100L)).thenReturn(List.of());

		assertThatThrownBy(() -> service.unassignProgramFromStudent(7L, 100L, 50L))
			.isInstanceOf(NotFoundException.class);

		verify(blockRepository, never()).delete(any());
	}

	@Test
	void unassign_singleUnambiguousCopy_isDeleted() {
		TrainingBlock template = templateOf(100L, 7L, "Push Pull Legs");
		TrainingBlock copy = assignedCopy(201L, 7L, 50L, "Push Pull Legs");

		when(blockRepository.findById(100L)).thenReturn(Optional.of(template));
		when(blockRepository.findByTemplateIdAndIsTemplateFalse(100L)).thenReturn(List.of(copy));

		service.unassignProgramFromStudent(7L, 100L, 50L);

		verify(blockRepository).delete(copy);
	}

}
