package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.core.security.service.AuditLogService;
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
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code DietProgramService} erişim kontrolü testleri.
 * <p>
 * Diyet programı kişisel sağlık verisidir (kilo, hedef, öğün planı). Program kimliği
 * URL'den geldiği için erişim tamamen servis katmanındaki sahiplik kontrolüne bağlıdır.
 * Programa iki taraf erişebilir: <b>sahibi</b> (sporcu) ve <b>atayan koç</b>.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class DietProgramServiceTest {

	@Mock
	private DietProgramRepository programRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private NutritionMapper nutritionMapper;

	@Mock
	private AuditLogService auditLogService;

	@Mock
	private ApplicationEventPublisher eventPublisher;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	@Mock
	private ClientRepository clientRepository;

	private DietProgramService service;

	private AppUser owner;

	private AppUser assignedCoach;

	private AppUser outsider;

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new DietProgramService(programRepository, userContextService, nutritionMapper, auditLogService,
				fixedClock, eventPublisher, messagingTemplate, clientRepository);

		owner = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		assignedCoach = userWithId(2L, "koc@test.com", UserRole.COACH);
		outsider = userWithId(99L, "yabanci@test.com", UserRole.COACH);
	}

	/** Sahibi sporcu (1), atayan koçu (2) olan program. */
	private DietProgram program() {
		DietProgram program = new DietProgram();
		program.setId(10L);
		program.setOwner(owner);
		program.setCoach(assignedCoach);
		return program;
	}

	private void currentUserIs(AppUser user) {
		lenient().when(userContextService.getCurrentUser()).thenReturn(user);
	}

	// ---------------------------------------------------------------------------
	// Programı görüntüleme — yalnızca sahibi ve atayan koç
	// ---------------------------------------------------------------------------

	@Test
	void getProgram_neitherOwnerNorAssignedCoach_throwsAndReturnsNoData() {
		currentUserIs(outsider);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		assertThatThrownBy(() -> service.getProgram(10L)).isInstanceOf(BadRequestException.class);

		// Yabancı kullanıcıya program verisi hiç hazırlanmamalı.
		verify(nutritionMapper, never()).toProgramResponse(any(), any());
	}

	@Test
	void getProgram_owner_isAllowed() {
		currentUserIs(owner);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		assertThatCode(() -> service.getProgram(10L)).doesNotThrowAnyException();

		verify(nutritionMapper).toProgramResponse(any(), any());
	}

	@Test
	void getProgram_assignedCoach_isAllowed() {
		currentUserIs(assignedCoach);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		assertThatCode(() -> service.getProgram(10L)).doesNotThrowAnyException();
	}

	@Test
	void getProgram_unknownProgram_throwsNotFound() {
		currentUserIs(owner);
		when(programRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getProgram(404L)).isInstanceOf(NotFoundException.class);
	}

	// ---------------------------------------------------------------------------
	// Programı aktif etme — yalnızca sahibi (koç bile yapamaz)
	// ---------------------------------------------------------------------------

	@Test
	void activateProgram_assignedCoachTriesToActivate_isRejected() {
		currentUserIs(assignedCoach);
		when(programRepository.findByOwnerIdAndMainTrue(2L)).thenReturn(Optional.empty());
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		// Aktif programı seçmek sporcunun kendi kararıdır; koç zorlayamaz.
		assertThatThrownBy(() -> service.activateProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(programRepository, never()).save(any());
	}

	@Test
	void activateProgram_owner_marksProgramAsMain() {
		DietProgram program = program();
		currentUserIs(owner);
		when(programRepository.findByOwnerIdAndMainTrue(1L)).thenReturn(Optional.empty());
		when(programRepository.findById(10L)).thenReturn(Optional.of(program));

		service.activateProgram(10L);

		assertThat(program.isMain()).isTrue();
		verify(programRepository).save(program);
	}

	// ---------------------------------------------------------------------------
	// Program silme — sahibi veya atayan koç
	// ---------------------------------------------------------------------------

	@Test
	void deleteProgram_neitherOwnerNorAssignedCoach_throwsAndDeletesNothing() {
		currentUserIs(outsider);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		assertThatThrownBy(() -> service.deleteProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(programRepository, never()).delete(any());
	}

	@Test
	void deleteProgram_coachWhoIsNotTheAssignedOne_isRejected() {
		AppUser anotherCoach = userWithId(77L, "baska.koc@test.com", UserRole.COACH);
		currentUserIs(anotherCoach);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		// COACH rolüne sahip olmak yetmez; programı atayan koç olmak gerekir.
		assertThatThrownBy(() -> service.deleteProgram(10L)).isInstanceOf(BadRequestException.class);

		verify(programRepository, never()).delete(any());
	}

	// ---------------------------------------------------------------------------
	// Sahipsiz (orphaned) program onayı — yalnızca sahibi
	// ---------------------------------------------------------------------------

	@Test
	void approveOrphanedDietProgram_notTheOwner_isRejected() {
		currentUserIs(outsider);
		when(programRepository.findById(10L)).thenReturn(Optional.of(program()));

		assertThatThrownBy(() -> service.approveOrphanedDietProgram(10L, true)).isInstanceOf(BadRequestException.class);

		verify(programRepository, never()).delete(any());
	}

}
