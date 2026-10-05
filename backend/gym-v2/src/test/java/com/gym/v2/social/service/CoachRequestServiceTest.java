package com.gym.v2.social.service;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.ConflictException;
import com.gym.v2.social.entity.PairingStatus;
import com.gym.v2.social.repository.PairingRequestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * {@code CoachRequestService} erişim ve rol doğrulama testleri.
 */
@ExtendWith(MockitoExtension.class)
class CoachRequestServiceTest {

	@Mock
	private PairingRequestRepository pairingRequestRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private CoachRepository coachRepository;

	private CoachRequestService service;

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new CoachRequestService(pairingRequestRepository, clientRepository, coachRepository, fixedClock);
	}

	@Test
	void sendRequestToCoach_byNonClient_isForbiddenAndSavesNothing() {
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.sendRequestToCoach(1L, 2L)).isInstanceOf(AccessDeniedException.class)
			.hasMessage("Sadece sporcular koçluk isteği gönderebilir.");

		verifyNoInteractions(pairingRequestRepository);
	}

	@Test
	void pendingOrAlreadyCoached_isConflictAndSavesNothing() {
		ClientEntity client = new ClientEntity();
		client.setUserId(1L);
		CoachEntity coach = new CoachEntity();
		coach.setUserId(2L);

		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(client));
		when(coachRepository.findByUserId(2L)).thenReturn(Optional.of(coach));

		// Koşul 1: :67 beklemede olan istek
		when(pairingRequestRepository.existsByClient_UserIdAndCoach_UserIdAndStatus(1L, 2L, PairingStatus.PENDING))
			.thenReturn(true);

		assertThatThrownBy(() -> service.sendRequestToCoach(1L, 2L)).isInstanceOf(ConflictException.class)
			.hasMessage("Bu antrenöre zaten beklemede olan bir isteğiniz bulunuyor.");

		// Koşul 2: :72 zaten çalışıyor
		when(pairingRequestRepository.existsByClient_UserIdAndCoach_UserIdAndStatus(1L, 2L, PairingStatus.PENDING))
			.thenReturn(false);
		client.setCoachId(2L);

		assertThatThrownBy(() -> service.sendRequestToCoach(1L, 2L)).isInstanceOf(ConflictException.class)
			.hasMessage("Bu antrenör ile zaten çalışıyorsunuz.");

		verify(pairingRequestRepository, never()).save(any());
	}

}
