package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.social.dto.CreateProgressRequest;
import com.gym.v2.social.entity.CoachStudentProgress;
import com.gym.v2.social.repository.CoachStudentProgressRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * {@code CoachStudentProgressService} — gelişim talebi oluşturma.
 * <p>
 * İki koruma test altında: koç yalnızca <b>kendi</b> öğrencisi için talep açabilir ve
 * görsel adresleri <b>sunucu adı olmadan</b> saklanır. İkincisi olmadan, talebi onaylamak
 * için görseli açan sporcunun IP adresi ve açılma anı, adresin sahibine gider.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class CoachStudentProgressServiceTest {

	@Mock
	private CoachStudentProgressRepository progressRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private SocialMapper socialMapper;

	private CoachStudentProgressService service;

	@BeforeEach
	void setUp() {
		service = new CoachStudentProgressService(progressRepository, coachRepository, clientRepository, userRepository,
				socialMapper);

		SecurityContextHolder.getContext()
			.setAuthentication(
					new UsernamePasswordAuthenticationToken("coach@test.com", null, java.util.Collections.emptyList()));

		AppUser coachUser = AppUser.builder().email("coach@test.com").build();
		ReflectionTestUtils.setField(coachUser, "id", 2L);
		when(userRepository.findByEmail("coach@test.com")).thenReturn(Optional.of(coachUser));
	}

	private void coachOwnsClient() {
		CoachEntity coach = new CoachEntity();
		ReflectionTestUtils.setField(coach, "userId", 2L);
		when(coachRepository.findByUserId(2L)).thenReturn(Optional.of(coach));

		ClientEntity client = new ClientEntity();
		ReflectionTestUtils.setField(client, "userId", 1L);
		client.setCoachId(2L);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(client));
	}

	@Test
	void imageUrlsPointingToAnotherHost_areStoredAsPathOnly() {
		coachOwnsClient();

		service
			.createProgressRequest(new CreateProgressRequest(1L, "Rumuz", "https://saldirgan.com/api/v1/files/once.jpg",
					"http://10.0.2.2:8082/api/v1/files/sonra.png", "aciklama"));

		ArgumentCaptor<CoachStudentProgress> captor = ArgumentCaptor.forClass(CoachStudentProgress.class);
		verify(progressRepository).save(captor.capture());

		assertThat(captor.getValue().getBeforeImageUrl()).isEqualTo("/api/v1/files/once.jpg");
		assertThat(captor.getValue().getAfterImageUrl()).isEqualTo("/api/v1/files/sonra.png");
	}

	@Test
	void requestForSomeoneElsesStudent_isRejectedAndSavesNothing() {
		CoachEntity coach = new CoachEntity();
		ReflectionTestUtils.setField(coach, "userId", 2L);
		when(coachRepository.findByUserId(2L)).thenReturn(Optional.of(coach));

		ClientEntity foreignClient = new ClientEntity();
		ReflectionTestUtils.setField(foreignClient, "userId", 1L);
		foreignClient.setCoachId(99L);
		when(clientRepository.findByUserId(1L)).thenReturn(Optional.of(foreignClient));

		assertThatThrownBy(() -> service.createProgressRequest(new CreateProgressRequest(1L, "Rumuz",
				"/api/v1/files/once.jpg", "/api/v1/files/sonra.png", "aciklama")))
			.isInstanceOf(BadRequestException.class);

		verify(progressRepository, never()).save(any());
	}

}
