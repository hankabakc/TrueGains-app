package com.gym.v2.measurement.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.measurement.entity.Measurement;
import com.gym.v2.measurement.repository.MeasurementRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * {@code MeasurementService} sahiplik (IDOR) sınırları.
 * <p>
 * Ölçümler kişisel sağlık verisidir (kilo, yağ oranı, vücut ölçüleri). Hem ölçüm hem de
 * sporcu kimliği URL'den geldiği için tek koruma servis katmanındaki sahiplik ve
 * koç-sporcu ilişkisi kontrolüdür.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class MeasurementOwnershipTest {

	@Mock
	private MeasurementRepository measurementRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private MeasurementMapper measurementMapper;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private EncryptionConverter encryptionConverter;

	private MeasurementService service;

	private AppUser owner;

	private AppUser otherClient;

	private AppUser assignedCoach;

	private AppUser otherCoach;

	private final Pageable pageable = PageRequest.of(0, 20);

	private AppUser userWithId(Long id, String email, UserRole role) {
		AppUser user = AppUser.builder().email(email).role(role).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new MeasurementService(measurementRepository, userContextService, measurementMapper, clientRepository,
				encryptionConverter, fixedClock);

		owner = userWithId(1L, "sporcu@test.com", UserRole.CLIENT);
		otherClient = userWithId(99L, "baska.sporcu@test.com", UserRole.CLIENT);
		assignedCoach = userWithId(2L, "koc@test.com", UserRole.COACH);
		otherCoach = userWithId(77L, "baska.koc@test.com", UserRole.COACH);
	}

	private void currentUserIs(AppUser user) {
		lenient().when(userContextService.getCurrentUser()).thenReturn(user);
	}

	/** Sahibi sporcu 1 olan ölçüm. */
	private Measurement measurement() {
		Measurement measurement = new Measurement();
		measurement.setId(5L);
		measurement.setUser(owner);
		return measurement;
	}

	private ClientEntity clientLinkedTo(Long coachId) {
		ClientEntity entity = new ClientEntity();
		entity.setCoachId(coachId);
		return entity;
	}

	// ---------------------------------------------------------------------------
	// deleteMeasurement — yalnızca ölçümün sahibi
	// ---------------------------------------------------------------------------

	@Test
	void deleteMeasurement_notTheOwner_isRejectedAndDeletesNothing() {
		currentUserIs(otherClient);
		when(measurementRepository.findById(5L)).thenReturn(Optional.of(measurement()));

		assertThatThrownBy(() -> service.deleteMeasurement(5L)).isInstanceOf(AccessDeniedException.class);

		verify(measurementRepository, never()).delete(any());
	}

	@Test
	void deleteMeasurement_coachOfThatClient_isRejected() {
		// Koç sporcunun ölçümünü görebilir ama silemez.
		currentUserIs(assignedCoach);
		when(measurementRepository.findById(5L)).thenReturn(Optional.of(measurement()));

		assertThatThrownBy(() -> service.deleteMeasurement(5L)).isInstanceOf(AccessDeniedException.class);

		verify(measurementRepository, never()).delete(any());
	}

	@Test
	void deleteMeasurement_owner_deletes() {
		Measurement measurement = measurement();
		currentUserIs(owner);
		when(measurementRepository.findById(5L)).thenReturn(Optional.of(measurement));

		service.deleteMeasurement(5L);

		verify(measurementRepository).delete(measurement);
	}

	@Test
	void deleteMeasurement_unknownMeasurement_throwsNotFound() {
		when(measurementRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.deleteMeasurement(404L)).isInstanceOf(NotFoundException.class);

		verify(measurementRepository, never()).delete(any());
	}

	// ---------------------------------------------------------------------------
	// shareMeasurementsWithCoach — toplu paylaşım; kısmi paylaşım olmamalı
	// ---------------------------------------------------------------------------

	private Measurement measurementOf(Long id, AppUser user, boolean alreadyShared) {
		Measurement measurement = new Measurement();
		measurement.setId(id);
		measurement.setUser(user);
		measurement.setIsSharedWithCoach(alreadyShared);
		return measurement;
	}

	@Test
	void shareMeasurements_listContainsSomeoneElsesMeasurement_isRejectedAndSharesNothing() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(measurementRepository.findAllById(List.of(5L, 6L)))
			.thenReturn(List.of(measurementOf(5L, owner, false), measurementOf(6L, otherClient, false)));

		assertThatThrownBy(() -> service.shareMeasurementsWithCoach(List.of(5L, 6L)))
			.isInstanceOf(AccessDeniedException.class);

		// Kendi kaydı da paylaşılmamalı: liste ya tümüyle geçerlidir ya da hiç.
		verify(measurementRepository, never()).bulkShareWithCoach(any(), any());
	}

	@Test
	void shareMeasurements_someIdsDoNotExist_isRejectedAndSharesNothing() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		// İki kimlik gönderildi, veritabanı bir kayıt döndü.
		when(measurementRepository.findAllById(List.of(5L, 404L))).thenReturn(List.of(measurementOf(5L, owner, false)));

		assertThatThrownBy(() -> service.shareMeasurementsWithCoach(List.of(5L, 404L)))
			.isInstanceOf(NotFoundException.class);

		verify(measurementRepository, never()).bulkShareWithCoach(any(), any());
	}

	@Test
	void shareMeasurements_alreadySharedMeasurement_isRejectedAndSharesNothing() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(measurementRepository.findAllById(List.of(5L, 6L)))
			.thenReturn(List.of(measurementOf(5L, owner, false), measurementOf(6L, owner, true)));

		assertThatThrownBy(() -> service.shareMeasurementsWithCoach(List.of(5L, 6L)))
			.isInstanceOf(BadRequestException.class);

		verify(measurementRepository, never()).bulkShareWithCoach(any(), any());
	}

	@Test
	void shareMeasurements_userWithoutCoach_isRejectedAndSharesNothing() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(null)));

		assertThatThrownBy(() -> service.shareMeasurementsWithCoach(List.of(5L)))
			.isInstanceOf(BadRequestException.class);

		// Antrenör yokken kayıtlar okunmamalı bile.
		verify(measurementRepository, never()).findAllById(any());
		verify(measurementRepository, never()).bulkShareWithCoach(any(), any());
	}

	@Test
	void shareMeasurements_duplicateIds_areDeduplicatedBeforeTheOwnershipCheck() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(measurementRepository.findAllById(List.of(5L))).thenReturn(List.of(measurementOf(5L, owner, false)));

		// Mükerrer kimlik gönderilirse "bulunan sayısı = istenen sayısı" kontrolü
		// tekrarlar yüzünden yanlışlıkla patlamamalı.
		service.shareMeasurementsWithCoach(List.of(5L, 5L));

		verify(measurementRepository).bulkShareWithCoach(1L, List.of(5L));
	}

	@Test
	void shareMeasurements_ownUnsharedMeasurements_areShared() {
		currentUserIs(owner);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(measurementRepository.findAllById(List.of(5L, 6L)))
			.thenReturn(List.of(measurementOf(5L, owner, false), measurementOf(6L, owner, false)));

		service.shareMeasurementsWithCoach(List.of(5L, 6L));

		verify(measurementRepository).bulkShareWithCoach(1L, List.of(5L, 6L));
	}

	@Test
	void shareMeasurements_emptyList_touchesNothing() {
		service.shareMeasurementsWithCoach(List.of());

		verifyNoInteractions(measurementRepository, clientRepository, userContextService);
	}

	// ---------------------------------------------------------------------------
	// getClientMeasurements — yalnızca sporcunun kendi koçu
	// ---------------------------------------------------------------------------

	@Test
	void getClientMeasurements_clientOfAnotherCoach_isRejectedAndReadsNothing() {
		currentUserIs(otherCoach);
		// Sporcu 1, koç 2'ye bağlı; sorgulayan koç 77.
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));

		assertThatThrownBy(() -> service.getClientMeasurements(1L, pageable)).isInstanceOf(AccessDeniedException.class);

		verify(measurementRepository, never()).findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(anyLong(),
				any(Pageable.class));
	}

	@Test
	void getClientMeasurements_clientWithoutCoach_isRejected() {
		currentUserIs(otherCoach);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(null)));

		assertThatThrownBy(() -> service.getClientMeasurements(1L, pageable)).isInstanceOf(AccessDeniedException.class);

		verify(measurementRepository, never()).findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(anyLong(),
				any(Pageable.class));
	}

	@Test
	void getClientMeasurements_ownClient_readsOnlyTheSharedOnes() {
		currentUserIs(assignedCoach);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(clientLinkedTo(2L)));
		when(measurementRepository.findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(1L, pageable))
			.thenReturn(Page.empty());

		service.getClientMeasurements(1L, pageable);

		// Paylaşılmamış ölçümleri getiren bir sorgu kullanılmamalı.
		verify(measurementRepository).findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(1L, pageable);
	}

	@Test
	void getClientMeasurements_unknownClient_throwsNotFound() {
		currentUserIs(assignedCoach);
		when(clientRepository.findByUserId(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getClientMeasurements(404L, pageable)).isInstanceOf(NotFoundException.class);
	}

}
