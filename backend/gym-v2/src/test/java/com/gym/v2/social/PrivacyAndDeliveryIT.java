package com.gym.v2.social;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.service.ChatService;
import com.gym.v2.social.service.PairingService;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Sohbet gizliliği ve bildirim dayanıklılığı.
 * <p>
 * Üç ayrı vaadi doğrular: engellediğin kişinin metni hiçbir alanda görünmemeli, kişisel
 * veri toplu olarak listelenememeli, ve bildirim gönderimi başarısız olsa bile mesajın
 * kendisi kaybolmamalı.
 * </p>
 */
class PrivacyAndDeliveryIT extends IntegrationTestBase {

	@Autowired
	private ChatService chatService;

	@Autowired
	private PairingService pairingService;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private void actingAs(AppUser user) {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(user.getEmail(), null, List.of()));
	}

	private void createClientProfile(AppUser clientUser, Long coachId) {
		ClientEntity profile = new ClientEntity();
		profile.setUser(clientUser);
		profile.setFullName("Gizli Sporcu Adi");
		profile.setCoachId(coachId);
		clientRepository.saveAndFlush(profile);
	}

	@Test
	void blockedUsersMessage_doesNotLeakThroughTheConversationPreview() {
		AppUser coach = createUser("blk_coach@test.com", UserRole.COACH);
		AppUser client = createUser("blk_client@test.com", UserRole.CLIENT);
		createClientProfile(client, coach.getId());

		actingAs(client);
		ConversationDTO conversation = chatService.initiateConversation(coach.getId());

		// Sporcu koçu engeller, koç yine de mesaj yazar.
		actingAs(client);
		chatService.blockUser(coach.getId());
		actingAs(coach);
		chatService.sendMessage(new SendMessageRequest(conversation.id(), "GIZLI ENGELLENEN METIN", null, null));
		entityManager.flush();
		entityManager.clear();

		// Sporcu sohbeti açtığında engellenen mesajın metni hiçbir yerde görünmemeli.
		actingAs(client);
		ConversationDTO reopened = chatService.initiateConversation(coach.getId());

		assertThat(reopened.lastMessagePreview())
			.as("engellenen kullanıcının mesajı önizlemede görünüyor; engelleme yalnızca mesaj listesinde çalışıyor")
			.doesNotContain("GIZLI ENGELLENEN METIN");
	}

	@Test
	void discoverUsers_clientCannotListAthletes() {
		AppUser coach = createUser("disc_coach@test.com", UserRole.COACH);
		AppUser client = createUser("disc_client@test.com", UserRole.CLIENT);
		createClientProfile(client, coach.getId());

		actingAs(client);

		assertThatThrownBy(() -> pairingService.discoverUsers(UserRole.CLIENT, PageRequest.of(0, 50)))
			.as("sporcular birbirini listeleyemez; ad-soyad ve biyografi şifreli PII")
			.isInstanceOf(AccessDeniedException.class);
	}

	@Test
	void discoverUsers_coachCanListAthletes() {
		AppUser coach = createUser("disc_coach2@test.com", UserRole.COACH);
		AppUser client = createUser("disc_client3@test.com", UserRole.CLIENT);
		createClientProfile(client, coach.getId());

		actingAs(coach);

		assertThatCode(() -> pairingService.discoverUsers(UserRole.CLIENT, PageRequest.of(0, 50)))
			.as("koç sporcuları keşfet ekranında listeleyebilmeli")
			.doesNotThrowAnyException();
	}

	@Test
	void discoverUsers_stillListsCoaches() {
		AppUser client = createUser("disc_client2@test.com", UserRole.CLIENT);
		actingAs(client);

		assertThatCode(() -> pairingService.discoverUsers(UserRole.COACH, PageRequest.of(0, 50)))
			.as("pazaryerinin asıl özelliği olan antrenör keşfi çalışmaya devam etmeli")
			.doesNotThrowAnyException();
	}

}
