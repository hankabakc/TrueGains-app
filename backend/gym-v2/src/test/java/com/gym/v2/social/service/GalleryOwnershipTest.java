package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import com.gym.v2.social.entity.ClientGallery;
import com.gym.v2.social.entity.CoachGallery;
import com.gym.v2.social.repository.ClientGalleryRepository;
import com.gym.v2.social.repository.CoachGalleryRepository;
import com.gym.v2.social.repository.CoachReviewRepository;
import com.gym.v2.social.repository.CoachStudentProgressRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Galeri silme yollarının sahiplik kontrolü (sporcu ve koç galerileri).
 * <p>
 * Galeri öğeleri kullanıcıların yüklediği fotoğraflardır. Öğe kimliği URL'den gelir;
 * koruma olmazsa bir kullanıcı başkasının fotoğrafını silebilir.
 * </p>
 * <p>
 * Her iki servis de oturum sahibini {@code SecurityUtils.getCurrentUserEmail()} ile
 * çözer. Test bağlamında bu {@code null} döner, bu yüzden {@code findByEmail} çağrısı
 * {@code any()} ile karşılanır.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class GalleryOwnershipTest {

	// --- ClientGalleryService bağımlılıkları ---
	@Mock
	private ClientGalleryRepository clientGalleryRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private SocialMapper socialMapper;

	// --- CoachProfileService ek bağımlılıkları ---
	@Mock
	private CoachRepository coachRepository;

	@Mock
	private CoachGalleryRepository coachGalleryRepository;

	@Mock
	private CoachReviewRepository reviewRepository;

	@Mock
	private ClientSubscriptionRepository subscriptionRepository;

	@Mock
	private CoachStudentProgressRepository progressRepository;

	@Mock
	private EncryptionConverter encryptionConverter;

	private ClientGalleryService clientGalleryService;

	private CoachProfileService coachProfileService;

	private AppUser currentUser;

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);

		clientGalleryService = new ClientGalleryService(clientGalleryRepository, clientRepository, userRepository,
				socialMapper);
		coachProfileService = new CoachProfileService(coachRepository, coachGalleryRepository, reviewRepository,
				clientRepository, userRepository, socialMapper, subscriptionRepository, progressRepository, fixedClock,
				encryptionConverter);

		currentUser = userWithId(1L, "kullanici@test.com");
		lenient().when(userRepository.findByEmail(any())).thenReturn(Optional.of(currentUser));
	}

	// ---------------------------------------------------------------------------
	// Sporcu galerisi
	// ---------------------------------------------------------------------------

	private ClientGallery clientGalleryOwnedBy(Long ownerUserId) {
		ClientEntity owner = new ClientEntity();
		owner.setUserId(ownerUserId);

		ClientGallery item = new ClientGallery();
		item.setId(5L);
		item.setClient(owner);
		return item;
	}

	@Test
	void deleteClientGalleryItem_photoBelongsToAnotherUser_throwsAndDeletesNothing() {
		when(clientGalleryRepository.findById(5L)).thenReturn(Optional.of(clientGalleryOwnedBy(99L)));

		assertThatThrownBy(() -> clientGalleryService.deleteGalleryItem(5L)).isInstanceOf(BadRequestException.class);

		verify(clientGalleryRepository, never()).delete(any());
	}

	@Test
	void deleteClientGalleryItem_unknownItem_throwsNotFound() {
		when(clientGalleryRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> clientGalleryService.deleteGalleryItem(404L)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void deleteClientGalleryItem_ownPhoto_isDeleted() {
		ClientGallery item = clientGalleryOwnedBy(1L);
		when(clientGalleryRepository.findById(5L)).thenReturn(Optional.of(item));

		clientGalleryService.deleteGalleryItem(5L);

		verify(clientGalleryRepository).delete(item);
	}

	// ---------------------------------------------------------------------------
	// Koç galerisi
	// ---------------------------------------------------------------------------

	private CoachGallery coachGalleryOwnedBy(Long ownerUserId) {
		CoachEntity owner = new CoachEntity();
		owner.setUserId(ownerUserId);

		CoachGallery item = new CoachGallery();
		item.setId(7L);
		item.setCoach(owner);
		return item;
	}

	@Test
	void deleteCoachGalleryItem_photoBelongsToAnotherCoach_throwsAndDeletesNothing() {
		when(coachGalleryRepository.findById(7L)).thenReturn(Optional.of(coachGalleryOwnedBy(99L)));

		assertThatThrownBy(() -> coachProfileService.deleteGalleryItem(7L)).isInstanceOf(BadRequestException.class);

		verify(coachGalleryRepository, never()).delete(any());
	}

	@Test
	void deleteCoachGalleryItem_ownPhoto_isDeleted() {
		CoachGallery item = coachGalleryOwnedBy(1L);
		when(coachGalleryRepository.findById(7L)).thenReturn(Optional.of(item));

		coachProfileService.deleteGalleryItem(7L);

		verify(coachGalleryRepository).delete(item);
	}

}
