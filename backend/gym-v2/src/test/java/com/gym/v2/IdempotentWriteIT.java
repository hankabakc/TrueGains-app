package com.gym.v2;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.repository.MessageRepository;
import com.gym.v2.social.service.ChatService;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.dto.WorkoutSessionRequestDTO;
import com.gym.v2.training.entity.WorkoutSession;
import com.gym.v2.training.repository.WorkoutSessionRepository;
import com.gym.v2.training.service.WorkoutSessionService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Tekrar koruması (G-79): servis, test şeması (entity eşlemesi) ve benzersizlik kısıtı
 * birlikte sınanır.
 */
class IdempotentWriteIT extends IntegrationTestBase {

	@Autowired
	private WorkoutSessionService workoutSessionService;

	@Autowired
	private WorkoutSessionRepository workoutSessionRepository;

	@Autowired
	private ChatService chatService;

	@Autowired
	private MessageRepository messageRepository;

	@PersistenceContext
	private EntityManager entityManager;

	private void actingAs(AppUser user) {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
	}

	@AfterEach
	void tearDown() {
		SecurityContextHolder.clearContext();
	}

	@Test
	void workoutSession_sameLocalIdTwice_isStoredOnce() {
		AppUser client = createUser("idem_ws@test.com", UserRole.CLIENT);
		actingAs(client);

		WorkoutSessionRequestDTO request = new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null,
				"yerel-ws-1");
		workoutSessionService.logWorkoutSession(request);
		entityManager.flush();
		entityManager.clear();

		workoutSessionService.logWorkoutSession(request);
		entityManager.flush();
		entityManager.clear();

		assertThat(workoutSessionRepository.findHistoryWithLogs(client.getId())).hasSize(1);
	}

	@Test
	void message_sameLocalIdTwice_isStoredOnce() {
		AppUser coach = createUser("idem_coach@test.com", UserRole.COACH);
		AppUser client = createUser("idem_client@test.com", UserRole.CLIENT);

		ClientEntity clientProfile = new ClientEntity();
		clientProfile.setUser(client);
		clientProfile.setFullName("Sporcu");
		clientProfile.setCoachId(coach.getId());
		clientRepository.saveAndFlush(clientProfile);

		actingAs(client);
		ConversationDTO conversation = chatService.initiateConversation(coach.getId());

		SendMessageRequest request = new SendMessageRequest(conversation.id(), "tek mesaj", null, null, "yerel-msg-1");
		chatService.sendMessage(request);
		entityManager.flush();
		entityManager.clear();

		chatService.sendMessage(request);
		entityManager.flush();
		entityManager.clear();

		assertThat(messageRepository.findVisibleMessages(conversation.id(), client.getId(), PageRequest.of(0, 10))
			.getTotalElements()).isEqualTo(1);
	}

	@Test
	void sameLocalId_differentUsers_bothStored() {
		AppUser a = createUser("idem_a@test.com", UserRole.CLIENT);
		AppUser b = createUser("idem_b@test.com", UserRole.CLIENT);

		actingAs(a);
		workoutSessionService
			.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null, "ortak-kimlik"));
		entityManager.flush();

		actingAs(b);
		workoutSessionService
			.logWorkoutSession(new WorkoutSessionRequestDTO("Gun 1", 600, List.of(), null, null, "ortak-kimlik"));
		entityManager.flush();
		entityManager.clear();

		assertThat(workoutSessionRepository.findHistoryWithLogs(a.getId())).hasSize(1);
		assertThat(workoutSessionRepository.findHistoryWithLogs(b.getId())).hasSize(1);
	}

	@Test
	void database_rejectsDuplicateLocalIdForSameUser() {
		AppUser client = createUser("idem_db@test.com", UserRole.CLIENT);

		WorkoutSession s1 = new WorkoutSession(client, "Gun 1", 60);
		s1.setLocalId("yerel-db");
		s1.onPersist(Instant.parse("2026-01-01T00:00:00Z"));
		workoutSessionRepository.saveAndFlush(s1);

		WorkoutSession s2 = new WorkoutSession(client, "Gun 1", 60);
		s2.setLocalId("yerel-db");
		s2.onPersist(Instant.parse("2026-01-01T00:00:00Z"));

		assertThatThrownBy(() -> workoutSessionRepository.saveAndFlush(s2))
			.isInstanceOf(DataIntegrityViolationException.class);
	}

}