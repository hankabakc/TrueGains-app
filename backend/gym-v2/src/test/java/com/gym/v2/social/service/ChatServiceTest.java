package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.core.service.NotificationService;
import com.gym.v2.finance.repository.SubscriptionPackageRepository;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.entity.Conversation;
import com.gym.v2.social.entity.Message;
import com.gym.v2.social.repository.ConversationRepository;
import com.gym.v2.social.repository.MessageRepository;
import com.gym.v2.social.repository.UserBlockRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * {@code ChatService} erişim kontrolü testleri.
 * <p>
 * Buradaki açık, projedeki en ağır gizlilik ihlali olurdu: konuşmanın tarafı olmayan bir
 * kullanıcı başkalarının özel mesajlarını okuyabilirdi. Konuşma kimliği URL'den geldiği
 * için koruma tamamen servis katmanındaki taraf kontrolüne bağlıdır.
 * </p>
 */
@ExtendWith(MockitoExtension.class)
class ChatServiceTest {

	@Mock
	private ConversationRepository conversationRepository;

	@Mock
	private MessageRepository messageRepository;

	@Mock
	private AppUserRepository userRepository;

	@Mock
	private UserContextService userContextService;

	@Mock
	private SimpMessagingTemplate messagingTemplate;

	@Mock
	private NotificationService notificationService;

	@Mock
	private SocialMapper socialMapper;

	@Mock
	private SocialMappingHelper socialMappingHelper;

	@Mock
	private UserBlockRepository userBlockRepository;

	@Mock
	private ClientRepository clientRepository;

	@Mock
	private CoachRepository coachRepository;

	@Mock
	private SubscriptionPackageRepository subscriptionPackageRepository;

	private ChatService service;

	private AppUser client;

	private AppUser coach;

	private AppUser outsider;

	private static final Pageable PAGE = PageRequest.of(0, 20);

	private AppUser userWithId(Long id, String email) {
		AppUser user = AppUser.builder().email(email).build();
		ReflectionTestUtils.setField(user, "id", id);
		return user;
	}

	@BeforeEach
	void setUp() {
		Clock fixedClock = Clock.fixed(Instant.parse("2026-01-01T00:00:00Z"), ZoneOffset.UTC);
		service = new ChatService(conversationRepository, messageRepository, userRepository, userContextService,
				messagingTemplate, notificationService, socialMapper, socialMappingHelper, userBlockRepository,
				clientRepository, coachRepository, subscriptionPackageRepository,
				new com.gym.v2.core.service.TransactionalEvents(), fixedClock);

		client = userWithId(1L, "client@test.com");
		coach = userWithId(2L, "coach@test.com");
		outsider = userWithId(99L, "yabanci@test.com");
	}

	/** Tarafları sporcu (1) ve koç (2) olan konuşma. */
	private Conversation conversation() {
		Conversation conv = new Conversation();
		conv.setId(10L);
		conv.setClient(client);
		conv.setCoach(coach);
		return conv;
	}

	private void currentUserIs(AppUser user) {
		lenient().when(userContextService.getCurrentUser()).thenReturn(user);
	}

	// ---------------------------------------------------------------------------
	// Mesaj okuma — konuşmanın tarafı olmayan erişemez
	// ---------------------------------------------------------------------------

	@Test
	void getMessages_userIsNotPartyToConversation_throwsAndReadsNoMessages() {
		currentUserIs(outsider);
		when(conversationRepository.findById(10L)).thenReturn(Optional.of(conversation()));

		assertThatThrownBy(() -> service.getMessages(10L, PAGE)).isInstanceOf(BadRequestException.class);

		// Yabancı kullanıcı hiçbir mesaj satırına ulaşamamalı.
		verify(messageRepository, never()).findVisibleMessages(any(), any(), any());
	}

	@Test
	void getMessages_unknownConversation_throwsNotFound() {
		currentUserIs(client);
		when(conversationRepository.findById(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.getMessages(404L, PAGE)).isInstanceOf(NotFoundException.class);
	}

	@Test
	void getMessages_clientPartyOfConversation_isAllowed() {
		currentUserIs(client);
		when(conversationRepository.findById(10L)).thenReturn(Optional.of(conversation()));
		when(messageRepository.findVisibleMessages(10L, 1L, PAGE)).thenReturn(Page.empty(PAGE));

		assertThatCode(() -> service.getMessages(10L, PAGE)).doesNotThrowAnyException();

		verify(messageRepository).findVisibleMessages(10L, 1L, PAGE);
	}

	@Test
	void getMessages_coachPartyOfConversation_isAllowed() {
		currentUserIs(coach);
		when(conversationRepository.findById(10L)).thenReturn(Optional.of(conversation()));
		when(messageRepository.findVisibleMessages(10L, 2L, PAGE)).thenReturn(new PageImpl<>(java.util.List.of()));

		assertThatCode(() -> service.getMessages(10L, PAGE)).doesNotThrowAnyException();
	}

	// ---------------------------------------------------------------------------
	// Okundu işaretleme — aynı korumaya tabi
	// ---------------------------------------------------------------------------

	@Test
	void markAsRead_userIsNotPartyToConversation_throws() {
		currentUserIs(outsider);
		when(conversationRepository.findById(10L)).thenReturn(Optional.of(conversation()));

		assertThatThrownBy(() -> service.markAsRead(10L)).isInstanceOf(BadRequestException.class);
	}

	// ---------------------------------------------------------------------------
	// Mesaj gönderme — yabancı konuşmaya yazamaz
	// ---------------------------------------------------------------------------

	@Test
	void sendMessage_userIsNotPartyToConversation_throwsAndSavesNothing() {
		currentUserIs(outsider);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));

		assertThatThrownBy(() -> service.sendMessage(new SendMessageRequest(10L, "merhaba", null, null, null)))
			.isInstanceOf(BadRequestException.class);

		verify(messageRepository, never()).save(any());
	}

	@Test
	void sendMessage_unknownConversation_throwsNotFound() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(404L)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> service.sendMessage(new SendMessageRequest(404L, "merhaba", null, null, null)))
			.isInstanceOf(NotFoundException.class);
	}

	// ---------------------------------------------------------------------------
	// Ek adresi — sunucu adı saklanmaz (H41)
	// ---------------------------------------------------------------------------

	/**
	 * Ek adresinde sunucu adı saklanırsa, mesajı açan kullanıcının cihazı o adrese istek
	 * atar ve IP'si ile açılma anı adresin sahibine gider (takip pikseli). Bu yüzden
	 * kaydedilen değer <b>yalnızca yol</b> olmalıdır; istemci kendi taban adresini ekler.
	 * <p>
	 * Engelli teslimat bilinçli olarak açık: mesaj yine kaydedilir ama WebSocket yayını
	 * ve bildirim adımları atlanır, böylece test yalnızca yazma yolunu ölçer.
	 * </p>
	 */
	@Test
	void sendMessage_attachmentPointingToAnotherHost_isStoredAsPathOnly() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));
		when(userBlockRepository.existsBlockBetween(any(), any())).thenReturn(true);

		service.sendMessage(new SendMessageRequest(10L, null, "https://saldirgan.com/api/v1/files/x.jpg", null, null));

		ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
		verify(messageRepository).save(captor.capture());
		assertThat(captor.getValue().getAttachmentUrl()).isEqualTo("/api/v1/files/x.jpg");
	}

	@Test
	void sendMessage_attachmentPointingToOurOwnHost_isAlsoStoredAsPathOnly() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));
		when(userBlockRepository.existsBlockBetween(any(), any())).thenReturn(true);

		service.sendMessage(new SendMessageRequest(10L, null, "http://10.0.2.2:8082/api/v1/files/y.png", null, null));

		ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
		verify(messageRepository).save(captor.capture());
		// Tek biçim: sunucu adı değişince eski ekler kırılmasın diye adres hiçbir zaman
		// mutlak saklanmaz.
		assertThat(captor.getValue().getAttachmentUrl()).isEqualTo("/api/v1/files/y.png");
	}

	@Test
	void sendMessage_emptyContentWithoutAttachmentOrPackage_isRejected() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));
		lenient().when(userBlockRepository.existsBlockBetween(any(), any())).thenReturn(false);

		assertThatThrownBy(() -> service.sendMessage(new SendMessageRequest(10L, "   ", null, null, null)))
			.isInstanceOf(BadRequestException.class);

		verify(messageRepository, never()).save(any());
	}

	@Test
	void sendMessage_sameLocalIdAlreadySaved_returnsExistingAndNeitherSavesNorNotifies() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));
		Message existing = new Message();
		when(messageRepository.findBySenderIdAndLocalId(1L, "yerel-1")).thenReturn(Optional.of(existing));

		service.sendMessage(new SendMessageRequest(10L, "merhaba", null, null, "yerel-1"));

		verify(socialMapper).toMessageDTO(existing);
		verify(messageRepository, never()).save(any());
		verifyNoInteractions(messagingTemplate, notificationService);
	}

	@Test
	void sendMessage_outsider_isRejectedBeforeLocalIdLookup() {
		currentUserIs(outsider);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));

		assertThatThrownBy(() -> service.sendMessage(new SendMessageRequest(10L, "merhaba", null, null, "yerel-1")))
			.isInstanceOf(BadRequestException.class);

		verify(messageRepository, never()).findBySenderIdAndLocalId(any(), any());
	}

	@Test
	void sendMessage_newLocalId_isStoredOnTheMessage() {
		currentUserIs(client);
		when(conversationRepository.findByIdWithUsers(10L)).thenReturn(Optional.of(conversation()));
		when(messageRepository.findBySenderIdAndLocalId(1L, "yerel-2")).thenReturn(Optional.empty());
		when(userBlockRepository.existsBlockBetween(any(), any())).thenReturn(true);

		service.sendMessage(new SendMessageRequest(10L, "merhaba", null, null, "yerel-2"));

		ArgumentCaptor<Message> captor = ArgumentCaptor.forClass(Message.class);
		verify(messageRepository).save(captor.capture());
		assertThat(captor.getValue().getLocalId()).isEqualTo("yerel-2");
	}

}
