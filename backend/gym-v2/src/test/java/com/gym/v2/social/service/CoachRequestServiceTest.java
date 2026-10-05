package com.gym.v2.social.service;

import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
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

}
