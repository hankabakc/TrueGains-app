package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.core.service.NotificationService;
import com.gym.v2.core.service.TransactionalEvents;
import com.gym.v2.core.util.FileUrls;
import com.gym.v2.social.dto.BulkReadEvent;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.MessageDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.entity.Conversation;
import com.gym.v2.social.entity.Message;
import com.gym.v2.social.entity.MessageStatus;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.finance.entity.SubscriptionPackage;
import com.gym.v2.finance.repository.SubscriptionPackageRepository;
import com.gym.v2.social.dto.BlockStatusDTO;
import com.gym.v2.social.entity.UserBlock;
import com.gym.v2.social.repository.ConversationRepository;
import com.gym.v2.social.repository.MessageRepository;
import com.gym.v2.social.repository.UserBlockRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * GYMAPP-V2 Sohbet (Chat) Servisi.
 */
@Service
public class ChatService {

	private final ConversationRepository conversationRepository;

	private final MessageRepository messageRepository;

	private final AppUserRepository userRepository;

	private final UserContextService userContextService;

	private final SimpMessagingTemplate messagingTemplate;

	private final NotificationService notificationService;

	private final SocialMapper socialMapper;

	private final SocialMappingHelper socialMappingHelper;

	private final TransactionalEvents transactionalEvents;

	private final Clock clock;

	private final UserBlockRepository userBlockRepository;

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	private final SubscriptionPackageRepository subscriptionPackageRepository;

	public ChatService(ConversationRepository conversationRepository, MessageRepository messageRepository,
			AppUserRepository userRepository, UserContextService userContextService,
			SimpMessagingTemplate messagingTemplate, NotificationService notificationService, SocialMapper socialMapper,
			SocialMappingHelper socialMappingHelper, UserBlockRepository userBlockRepository,
			ClientRepository clientRepository, CoachRepository coachRepository,
			SubscriptionPackageRepository subscriptionPackageRepository, TransactionalEvents transactionalEvents,
			Clock clock) {
		this.conversationRepository = conversationRepository;
		this.messageRepository = messageRepository;
		this.userRepository = userRepository;
		this.userContextService = userContextService;
		this.messagingTemplate = messagingTemplate;
		this.notificationService = notificationService;
		this.socialMapper = socialMapper;
		this.socialMappingHelper = socialMappingHelper;
		this.userBlockRepository = userBlockRepository;
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
		this.subscriptionPackageRepository = subscriptionPackageRepository;
		this.transactionalEvents = transactionalEvents;
		this.clock = clock;
	}

	@Transactional(readOnly = true)
	public Page<ConversationDTO> getMyConversations(Pageable pageable) {
		AppUser currentUser = userContextService.getCurrentUser();
		Long viewerId = currentUser.getId();
		Page<Conversation> page = conversationRepository.findActiveConversationsForUser(viewerId, pageable);

		List<Conversation> convs = page.getContent();
		if (convs.isEmpty()) {
			return Page.empty(pageable);
		}

		List<Long> convIds = convs.stream().map(Conversation::getId).toList();
		List<Long> clientIds = convs.stream().map(c -> c.getClient().getId()).distinct().toList();
		List<Long> coachIds = convs.stream().map(c -> c.getCoach().getId()).distinct().toList();

		Map<Long, Integer> unreadMap = new HashMap<>();
		for (Object[] row : messageRepository.countUnreadByConversationIds(convIds, viewerId)) {
			unreadMap.put(((Number) row[0]).longValue(), ((Number) row[1]).intValue());
		}

		Map<Long, Message> lastMsgMap = new HashMap<>();
		for (Message m : messageRepository.findLatestVisibleMessagesByConversationIds(convIds, viewerId)) {
			lastMsgMap.put(m.getConversation().getId(), m);
		}

		Map<Long, String> clientNameMap = clientRepository.findAllByUserIdIn(clientIds)
			.stream()
			.collect(Collectors.toMap(ClientEntity::getUserId, ClientEntity::getFullName));

		Map<Long, String> coachNameMap = coachRepository.findAllByUserIdIn(coachIds)
			.stream()
			.collect(Collectors.toMap(CoachEntity::getUserId, CoachEntity::getFullName));

		return page.map(conv -> new ConversationDTO(conv.getId(), conv.getClient().getId(),
				clientNameMap.getOrDefault(conv.getClient().getId(), "Sporcu"), conv.getCoach().getId(),
				coachNameMap.getOrDefault(conv.getCoach().getId(), "Antrenör"), conv.getLastMessageAt(),
				previewOf(lastMsgMap.get(conv.getId())), unreadMap.getOrDefault(conv.getId(), 0), conv.getIsActive()));
	}

	private String previewOf(Message m) {
		if (m == null) {
			return "Henüz mesaj yok";
		}
		if (m.getContent() != null && !m.getContent().isBlank()) {
			return m.getContent();
		}
		if (m.getAttachmentUrl() != null && !m.getAttachmentUrl().isBlank()) {
			return "[Görsel]";
		}
		if (m.getPackageId() != null) {
			return "[Üyelik Paketi]";
		}
		return "...";
	}

	@Transactional
	public MessageDTO sendMessage(SendMessageRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();

		// TEK SORGU: JOIN FETCH ile konuşmayı, client ve coach'u birlikte çek
		Conversation conversation = conversationRepository.findByIdWithUsers(request.conversationId())
			.orElseThrow(() -> new NotFoundException("Konuşma bulunamadı."));

		// ERİŞİM KONTROLÜ: Kullanıcı bu konuşmanın tarafı mı?
		if (!conversation.getClient().getId().equals(currentUser.getId())
				&& !conversation.getCoach().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu konuşmaya erişim yetkiniz yok.");
		}

		Long otherUserId = conversation.getClient().getId().equals(currentUser.getId())
				? conversation.getCoach().getId() : conversation.getClient().getId();
		boolean blockedDelivery = userBlockRepository.existsBlockBetween(currentUser.getId(), otherUserId);

		// HATA #25: Mesaj içeriği veya ek dosya boş olamaz kontrolü
		boolean hasContent = request.content() != null && !request.content().trim().isEmpty();
		boolean hasAttachment = request.attachmentUrl() != null && !request.attachmentUrl().trim().isEmpty();
		boolean hasPackage = request.packageId() != null;

		if (!hasContent && !hasAttachment && !hasPackage) {
			throw new BadRequestException("Mesaj içeriği veya ek dosya zorunludur.");
		}

		Message message = new Message();
		message.setConversation(conversation);
		message.setSender(currentUser);
		message.setContent(hasContent ? request.content().trim() : null);
		// Sunucu adı saklanmaz; gerekçe FileUrls'te.
		message.setAttachmentUrl(FileUrls.toStoredPath(request.attachmentUrl()));
		message.setStatus(MessageStatus.SENT);
		message.setBlockedDelivery(blockedDelivery);

		if (hasPackage) {
			SubscriptionPackage pkg = subscriptionPackageRepository.findById(request.packageId())
				.orElseThrow(() -> new NotFoundException("Paket bulunamadı."));
			message.setPackageId(pkg.getId());
			message.setPackageName(pkg.getName());
			message.setPackagePrice(pkg.getPrice());
		}

		Instant now = clock.instant();
		message.onPersist(now);

		Message saved = messageRepository.save(message);

		if (!blockedDelivery) {
			// Konuşma zamanını güncelle
			conversation.updateLastMessageAt(now);
			conversationRepository.save(conversation);
		}

		MessageDTO dto = socialMapper.toMessageDTO(saved);

		if (!blockedDelivery) {
			transactionalEvents
				.afterCommit(() -> messagingTemplate.convertAndSend("/topic/chat/" + request.conversationId(), dto));

			// Her iki tarafa da güncel conversation bilgisini kendi okunmamış sayısıyla
			// yayınla (Faz 3)
			ConversationDTO base = socialMapper.toConversationDTO(conversation);
			ConversationDTO forClient = enrichConversationDTO(base, conversation, conversation.getClient().getId());
			transactionalEvents.afterCommit(() -> messagingTemplate
				.convertAndSend("/topic/user/" + conversation.getClient().getId() + "/conversations", forClient));
			ConversationDTO forCoach = enrichConversationDTO(base, conversation, conversation.getCoach().getId());
			transactionalEvents.afterCommit(() -> messagingTemplate
				.convertAndSend("/topic/user/" + conversation.getCoach().getId() + "/conversations", forCoach));

			// Push bildirim gönder (Faz 2)
			Long recipientId = conversation.getClient().getId().equals(currentUser.getId())
					? conversation.getCoach().getId() : conversation.getClient().getId();

			String senderName = socialMappingHelper.resolveSenderFullName(currentUser);
			String preview = hasContent ? request.content().trim() : "[Görsel]";

			notificationService.sendPushNotification(recipientId, senderName, preview);
		}

		return dto;
	}

	@Transactional(readOnly = true)
	public Page<MessageDTO> getMessages(Long conversationId, Pageable pageable) {
		validateConversationAccess(conversationId);
		Long viewerId = userContextService.getCurrentUser().getId();
		Page<Message> messages = messageRepository.findVisibleMessages(conversationId, viewerId, pageable);
		return messages.map(socialMapper::toMessageDTO);
	}

	@Transactional
	public void markAsRead(Long conversationId) {
		validateConversationAccess(conversationId);
		AppUser currentUser = userContextService.getCurrentUser();
		List<Message> unreadMessages = messageRepository
			.findByConversationIdAndSenderIdNotAndStatusInAndBlockedDeliveryFalse(conversationId, currentUser.getId(),
					List.of(MessageStatus.SENT));

		if (!unreadMessages.isEmpty()) {
			List<Long> readMessageIds = unreadMessages.stream().map(Message::getId).toList();
			unreadMessages.forEach(m -> m.setStatus(MessageStatus.READ));
			messageRepository.saveAll(unreadMessages);

			// Okundu bilgisini WebSocket ile toplu yayınla
			BulkReadEvent event = new BulkReadEvent(conversationId, readMessageIds, MessageStatus.READ.name());
			transactionalEvents.afterCommit(
					() -> messagingTemplate.convertAndSend("/topic/chat/" + conversationId + "/bulk-read", event));
		}
	}

	@Transactional
	public ConversationDTO initiateConversation(Long otherUserId) {
		AppUser currentUser = userContextService.getCurrentUser();

		if (currentUser.getId().equals(otherUserId)) {
			throw new BadRequestException("Kendinizle sohbet başlatamazsınız.");
		}

		AppUser otherUser = userRepository.findById(otherUserId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		if (currentUser.getRole().equals(otherUser.getRole())) {
			throw new BadRequestException("Aynı roldeki kullanıcılarla sohbet başlatılamaz.");
		}

		Conversation conv = conversationRepository.findByClientIdAndCoachId(currentUser.getId(), otherUserId)
			.or(() -> conversationRepository.findByClientIdAndCoachId(otherUserId, currentUser.getId()))
			.orElseGet(() -> {
				Conversation newConv = new Conversation();
				if (UserRole.COACH.equals(currentUser.getRole())) {
					newConv.setCoach(currentUser);
					newConv.setClient(otherUser);
				}
				else {
					newConv.setClient(currentUser);
					newConv.setCoach(otherUser);
				}
				newConv.onPersist(clock.instant());
				newConv.setIsActive(true);
				return conversationRepository.save(newConv);
			});

		return enrichConversationDTO(socialMapper.toConversationDTO(conv), conv, currentUser.getId());
	}

	private ConversationDTO enrichConversationDTO(ConversationDTO dto, Conversation conv, Long viewerUserId) {
		// Önizleme, izleyiciye GÖRÜNEN son mesajdan üretilir.
		// Daha önce burada filtresiz `findFirstByConversationIdOrderBySentAtDesc` vardı:
		// engellenen kullanıcının mesajı listede ve okunmamış sayacında gizlenmesine
		// rağmen önizleme alanında metniyle birlikte görünüyordu. Sohbet listesi
		// (`previewOf`) doğru sorguyu zaten kullanıyordu; aynı mantığın ikinci kopyası
		// filtresiz kalmıştı.
		String lastMessagePreview = messageRepository
			.findLatestVisibleMessagesByConversationIds(List.of(conv.getId()), viewerUserId)
			.stream()
			.findFirst()
			.map(this::previewOf)
			.orElse("Henüz mesaj yok");

		// Okunmamış mesaj sayısı, COUNT sorgusuyla alınır. Daha önce tüm okunmamış mesaj
		// NESNELERİ belleğe çekilip `.size()` ile sayılıyordu: 500 okunmamış mesajı olan
		// bir sohbette her yeni mesaj 500 satır yüklüyordu.
		int unreadCount = (int) messageRepository.countUnreadForViewer(conv.getId(), viewerUserId);

		return new ConversationDTO(dto.id(), dto.clientId(), dto.clientFullName(), dto.coachId(), dto.coachFullName(),
				conv.getLastMessageAt(), lastMessagePreview, unreadCount, dto.isActive());
	}

	@Transactional
	public void blockUser(Long targetUserId) {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getId().equals(targetUserId)) {
			throw new BadRequestException("Kendinizi engelleyemezsiniz.");
		}
		AppUser target = userRepository.findById(targetUserId)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
		if (userBlockRepository.existsByBlockerIdAndBlockedId(currentUser.getId(), targetUserId)) {
			return;
		}
		UserBlock block = new UserBlock();
		block.setBlocker(currentUser);
		block.setBlocked(target);
		block.onPersist(clock.instant());
		userBlockRepository.save(block);
	}

	@Transactional
	public void unblockUser(Long targetUserId) {
		AppUser currentUser = userContextService.getCurrentUser();
		userBlockRepository.findByBlockerIdAndBlockedId(currentUser.getId(), targetUserId)
			.ifPresent(userBlockRepository::delete);
	}

	@Transactional(readOnly = true)
	public BlockStatusDTO getBlockStatus(Long otherUserId) {
		AppUser currentUser = userContextService.getCurrentUser();
		boolean blockedByMe = userBlockRepository.existsByBlockerIdAndBlockedId(currentUser.getId(), otherUserId);
		boolean blockedByOther = userBlockRepository.existsByBlockerIdAndBlockedId(otherUserId, currentUser.getId());
		return new BlockStatusDTO(blockedByMe, blockedByOther);
	}

	private void validateConversationAccess(Long conversationId) {
		AppUser currentUser = userContextService.getCurrentUser();
		Conversation conv = conversationRepository.findById(conversationId)
			.orElseThrow(() -> new NotFoundException("Konuşma bulunamadı."));
		if (!conv.getClient().getId().equals(currentUser.getId())
				&& !conv.getCoach().getId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu konuşmaya erişim yetkiniz yok.");
		}
	}

}
