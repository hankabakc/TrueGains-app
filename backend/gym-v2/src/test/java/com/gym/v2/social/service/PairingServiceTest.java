package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.social.dto.DiscoveryUserDto;
import com.gym.v2.social.entity.PairingRequest;
import com.gym.v2.social.entity.PairingStatus;
import com.gym.v2.social.repository.ConversationRepository;
import com.gym.v2.social.repository.PairingRequestRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/**
 * {@code PairingService.respondToRequest} sahiplik kontrolü.
 * <p>
 * Eşleşme isteğine yalnızca <b>isteğin gönderildiği koç</b> yanıt verebilir. Koruma
 * olmazsa başka bir koç, kendisine ait olmayan bir isteği kabul edip sporcuyu kendi
 * listesine bağlayabilirdi.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class PairingServiceTest {

	@Mock
	private PairingRequestRepository pairingRequestRepository;

	@Mock
	private ConversationRepository conversationRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository appUserRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private SocialMapper socialMapper;

	@Mock
	private EncryptionConverter encryptionConverter;

	private PairingService service;

	private AppUser currentCoachUser;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new PairingService(pairingRequestRepository, conversationRepository, coachRepository,
				clientRepository, appUserRepository, userContextService, socialMapper, fixedClock, encryptionConverter);

		currentCoachUser = userWithId(2L, "koc@test.com");
		lenient().when(userContextService.getCurrentUser()).thenReturn(currentCoachUser);
	}

	/**
	 * İsteği alan koçun kullanıcı kimliği {@code targetCoachUserId} olan eşleşme isteği.
	 */
	private PairingRequest requestAddressedTo(Long targetCoachUserId) {
		CoachEntity coach = new CoachEntity();
		coach.setUserId(targetCoachUserId);

		PairingRequest request = new PairingRequest();
		request.setId(30L);
		request.setCoach(coach);
		request.setStatus(PairingStatus.PENDING);
		return request;
	}

	@Test
	void respondToRequest_requestAddressedToAnotherCoach_throwsAndLeavesStatusUntouched() {
		PairingRequest request = requestAddressedTo(77L);
		when(pairingRequestRepository.findById(30L)).thenReturn(Optional.of(request));

		assertThatThrownBy(() -> service.respondToRequest(30L, true)).isInstanceOf(AccessDeniedException.class);

		// İstek durumu değişmemeli; aksi hâlde yabancı koç sporcuyu kendine bağlardı.
		assertThat(request.getStatus()).isEqualTo(PairingStatus.PENDING);
	}

	@Test
	void respondToRequest_unknownRequest_throwsNotFound() {
		when(pairingRequestRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.respondToRequest(404L, true)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void respondToRequest_ownRequestRejected_isMarkedRejected() {
		PairingRequest request = requestAddressedTo(2L);
		when(pairingRequestRepository.findById(30L)).thenReturn(Optional.of(request));

		service.respondToRequest(30L, false);

		assertThat(request.getStatus()).isEqualTo(PairingStatus.REJECTED);
	}

	@Test
	void discoverUsers_coachAsksForClients_returnsClientList() {
		currentCoachUser.setRole(UserRole.COACH);
		ClientEntity client = new ClientEntity();
		client.setUserId(9L);
		client.setFullName("Sporcu Bir");
		when(clientRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of(client)));

		Page<DiscoveryUserDto> result = service.discoverUsers(UserRole.CLIENT, Pageable.ofSize(10));

		assertThat(result.getContent()).hasSize(1);
		assertThat(result.getContent().get(0).userId()).isEqualTo(9L);
	}

	@Test
	void discoverUsers_clientAsksForClients_isDenied() {
		// Sporcuların birbirini sayfalayarak toplaması engellenmeli.
		currentCoachUser.setRole(UserRole.CLIENT);

		assertThatThrownBy(() -> service.discoverUsers(UserRole.CLIENT, Pageable.ofSize(10)))
			.isInstanceOf(AccessDeniedException.class);
	}

	@Test
	void discoverUsers_listedClientCannotReceivePairingRequest() {
		// Mimari: istek yönü sporcu → koç. Listelenen sporcuya istek düğmesi çıkmamalı.
		currentCoachUser.setRole(UserRole.COACH);
		ClientEntity client = new ClientEntity();
		client.setUserId(9L);
		when(clientRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of(client)));

		Page<DiscoveryUserDto> result = service.discoverUsers(UserRole.CLIENT, Pageable.ofSize(10));

		assertThat(result.getContent().get(0).canSendRequest()).isFalse();
	}

	/**
	 * Sıralama native sorgunun içinde yapılıyor. Buradan sıralı bir {@link Pageable}
	 * geçilirse Hibernate sorgunun sonuna İKİNCİ bir {@code ORDER BY} ekler ve sorgu
	 * sözdizimi bozulur — bu test o regresyonu kilitler.
	 */
	@Test
	void discoverCoaches_passesUnsortedPageable_soHibernateCannotAppendOrderBy() {
		when(coachRepository.searchCoaches(any(), any(), any(), any())).thenReturn(Page.empty());

		service.discoverCoaches(null, null, null, "rating", Pageable.ofSize(10));

		ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
		org.mockito.Mockito.verify(coachRepository).searchCoaches(any(), any(), any(), captor.capture());

		assertThat(captor.getValue().getSort().isSorted()).isFalse();
	}

	@Test
	void discoverCoaches_normalizesSortParameter() {
		when(coachRepository.searchCoaches(any(), any(), any(), any())).thenReturn(Page.empty());

		service.discoverCoaches(null, null, null, "newest", Pageable.ofSize(10));
		service.discoverCoaches(null, null, null, "price_asc", Pageable.ofSize(10));

		ArgumentCaptor<String> captor = ArgumentCaptor.forClass(String.class);
		org.mockito.Mockito.verify(coachRepository, org.mockito.Mockito.times(2))
			.searchCoaches(any(), any(), captor.capture(), any());

		// Tanınmayan değer sessizce varsayılana düşer; SQL'e ham girdi gitmez.
		assertThat(captor.getAllValues()).containsExactly("newest", "rating");
	}

}
