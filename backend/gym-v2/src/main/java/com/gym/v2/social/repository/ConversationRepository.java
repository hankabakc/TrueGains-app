package com.gym.v2.social.repository;

import com.gym.v2.social.entity.Conversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {

	@org.springframework.data.jpa.repository.Query("SELECT c FROM Conversation c WHERE "
			+ "(c.client.id = :userId OR c.coach.id = :userId) AND EXISTS "
			+ "(SELECT 1 FROM Message m WHERE m.conversation = c "
			+ "AND (m.blockedDelivery = false OR m.sender.id = :userId)) ORDER BY c.lastMessageAt DESC")
	Page<Conversation> findActiveConversationsForUser(
			@org.springframework.data.repository.query.Param("userId") Long userId, Pageable pageable);

	Optional<Conversation> findByClientIdAndCoachId(Long clientId, Long coachId);

	@org.springframework.data.jpa.repository.Query("SELECT c FROM Conversation c JOIN FETCH c.client JOIN FETCH c.coach WHERE c.id = :id")
	Optional<Conversation> findByIdWithUsers(@org.springframework.data.repository.query.Param("id") Long id);

}
