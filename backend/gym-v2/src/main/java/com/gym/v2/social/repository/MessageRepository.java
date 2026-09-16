package com.gym.v2.social.repository;

import com.gym.v2.social.entity.Message;
import com.gym.v2.social.entity.MessageStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface MessageRepository extends JpaRepository<Message, Long> {

	@Query("SELECT m FROM Message m WHERE m.conversation.id = :conversationId "
			+ "AND (m.blockedDelivery = false OR m.sender.id = :viewerId) ORDER BY m.sentAt ASC")
	Page<Message> findVisibleMessages(@Param("conversationId") Long conversationId, @Param("viewerId") Long viewerId,
			Pageable pageable);

	List<Message> findByConversationIdAndSenderIdNotAndStatusInAndBlockedDeliveryFalse(Long conversationId,
			Long senderId, List<MessageStatus> statuses);

	@Query("SELECT m FROM Message m "
			+ "WHERE (m.conversation.client.id = :userId OR m.conversation.coach.id = :userId) "
			+ "AND m.sender.id != :userId AND m.status = 'SENT'")
	List<Message> findIncomingSentMessagesForUser(@Param("userId") Long userId);

	Optional<Message> findFirstByConversationIdOrderBySentAtDesc(Long conversationId);

	/** Tekrar koruması (G-79): aynı gönderenin aynı yerel kimlikle kaydettiği mesaj. */
	Optional<Message> findBySenderIdAndLocalId(Long senderId, String localId);

	@Query("SELECT m.conversation.id, COUNT(m) FROM Message m WHERE "
			+ "m.conversation.id IN :conversationIds AND m.sender.id <> :viewerId "
			+ "AND m.status = com.gym.v2.social.entity.MessageStatus.SENT "
			+ "AND m.blockedDelivery = false GROUP BY m.conversation.id")
	List<Object[]> countUnreadByConversationIds(@Param("conversationIds") List<Long> conversationIds,
			@Param("viewerId") Long viewerId);

	@Query("SELECT m FROM Message m WHERE m.conversation.id IN :conversationIds "
			+ "AND (m.blockedDelivery = false OR m.sender.id = :viewerId) "
			+ "AND m.sentAt = (SELECT MAX(m2.sentAt) FROM Message m2 WHERE m2.conversation.id = m.conversation.id "
			+ "AND (m2.blockedDelivery = false OR m2.sender.id = :viewerId))")
	List<Message> findLatestVisibleMessagesByConversationIds(@Param("conversationIds") List<Long> conversationIds,
			@Param("viewerId") Long viewerId);

	/**
	 * Bir sohbette izleyiciye gelen okunmamış mesaj sayısı.
	 * <p>
	 * Varlık listesi çekip {@code .size()} ile saymanın yerine geçer: sayım için
	 * satırların belleğe yüklenmesine gerek yok.
	 * </p>
	 */
	@Query("SELECT COUNT(m) FROM Message m WHERE m.conversation.id = :conversationId "
			+ "AND m.sender.id <> :viewerId AND m.status = 'SENT' AND m.blockedDelivery = false")
	long countUnreadForViewer(@Param("conversationId") Long conversationId, @Param("viewerId") Long viewerId);

}
