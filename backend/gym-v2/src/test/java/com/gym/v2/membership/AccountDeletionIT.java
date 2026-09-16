package com.gym.v2.membership;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.auth.service.AuthenticationService;
import com.gym.v2.core.security.SecurityConstants;
import com.gym.v2.membership.service.AccountDeletionService;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.service.ChatService;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Hesap silmenin gerçekten sildiğini doğrular.
 * <p>
 * Bu testin normal testlerden farkı şu: burada aranan şey "işlem başarılı döndü mü"
 * değil, <b>verinin gerçekten gitmiş olması</b>. KVKK silme talebi yerine getirildiğinde
 * geriye kişiyi tanımlayan hiçbir iz kalmamalı; buna karşılık bilerek bırakılan
 * kayıtların da (ödeme, mesaj, değerlendirme) yerinde durduğu ayrıca doğrulanır — silme,
 * karşı tarafın verisini götürmemelidir.
 * </p>
 */
class AccountDeletionIT extends IntegrationTestBase {

	@Autowired
	private AccountDeletionService accountDeletionService;

	@Autowired
	private AuthenticationService authenticationService;

	@Autowired
	private RefreshTokenRepository refreshTokenRepository;

	@Autowired
	private ChatService chatService;

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

	private ClientEntity profileFor(AppUser user, Long coachId) {
		ClientEntity profile = new ClientEntity();
		profile.setUser(user);
		profile.setFullName("Ahmet Yilmaz");
		profile.setBio("Kisisel biyografi metni");
		profile.setHeightCm(180);
		profile.setWeightKg(new BigDecimal("80.00"));
		profile.setCoachId(coachId);
		return clientRepository.saveAndFlush(profile);
	}

	private long countWhere(String jpql, Long id) {
		return entityManager.createQuery(jpql, Long.class).setParameter("id", id).getSingleResult();
	}

	@Test
	void deletingAccount_erasesEveryPieceOfIdentifyingData() {
		AppUser coach = createUser("del_coach@test.com", UserRole.COACH);
		AppUser client = createUser("silinecek@test.com", UserRole.CLIENT);
		profileFor(client, coach.getId());
		authenticationService.login(new com.gym.v2.auth.dto.LoginRequest("silinecek@test.com", "Password123!",
				SecurityConstants.DEFAULT_DEVICE_ID));
		Long clientId = client.getId();
		entityManager.flush();

		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(client))
			.as("ön koşul: girişten sonra oturum olmalı")
			.isNotEmpty();

		actingAs(client);
		accountDeletionService.deleteMyAccount();
		entityManager.flush();
		entityManager.clear();

		AppUser after = userRepository.findById(clientId).orElseThrow();

		assertThat(after.getEmail()).as("e-posta serbest bırakılmalı ve kimlik taşımamalı")
			.doesNotContain("silinecek")
			.endsWith("@deleted.invalid");
		// EncryptionConverter null'ı okurken boş dizeye çeviriyor; aranan şey gösterim
		// biçimi değil, numaranın gerçekten kalmamış olması.
		assertThat(after.getPhoneNumber()).as("telefon numarası silinmeli").isNullOrEmpty();
		assertThat(after.getFcmToken()).as("bildirim token'ı silinmeli").isNull();
		assertThat(after.getIsActive()).as("hesap girişe kapatılmalı").isFalse();

		ClientEntity profileAfter = clientRepository.findByUserId(clientId).orElseThrow();
		assertThat(profileAfter.getFullName()).as("ad-soyad silinmeli").isEqualTo("Silinmiş kullanıcı");
		assertThat(profileAfter.getBio()).as("biyografi silinmeli").isNullOrEmpty();
		assertThat(profileAfter.getHeightCm()).as("vücut ölçüleri silinmeli").isNull();
		assertThat(profileAfter.getWeightKg()).isNull();
		assertThat(profileAfter.getCoachId()).as("koç bağı kopmalı").isNull();

		assertThat(refreshTokenRepository.findAllByUserOrderByExpiryDateAsc(after))
			.as("tüm oturumlar kapatılmalı; aksi hâlde silinen hesapla erişim sürer")
			.isEmpty();
	}

	@Test
	void deletedAccount_cannotLogInAnymore() {
		AppUser client = createUser("giris_yapamaz@test.com", UserRole.CLIENT);
		profileFor(client, null);

		actingAs(client);
		accountDeletionService.deleteMyAccount();
		entityManager.flush();
		entityManager.clear();

		assertThat(userRepository.findByEmail("giris_yapamaz@test.com"))
			.as("eski e-posta artık hiçbir hesaba ait olmamalı; kişi isterse aynı adresle yeniden kaydolabilmeli")
			.isEmpty();
	}

	@Test
	void deletingAccount_doesNotTakeTheOtherPartysMessagesWithIt() {
		AppUser coach = createUser("kalan_coach@test.com", UserRole.COACH);
		AppUser client = createUser("giden_client@test.com", UserRole.CLIENT);
		profileFor(client, coach.getId());

		actingAs(client);
		ConversationDTO conversation = chatService.initiateConversation(coach.getId());
		chatService.sendMessage(new SendMessageRequest(conversation.id(), "sporcunun mesaji", null, null, null));
		actingAs(coach);
		chatService.sendMessage(new SendMessageRequest(conversation.id(), "kocun mesaji", null, null, null));
		entityManager.flush();
		Long conversationId = conversation.id();

		actingAs(client);
		accountDeletionService.deleteMyAccount();
		entityManager.flush();
		entityManager.clear();

		// Karar: mesajlar kalır, gönderen kimliksizleşir. Koç konuşmayı bütün görmeli.
		assertThat(countWhere("SELECT COUNT(m) FROM Message m WHERE m.conversation.id = :id", conversationId))
			.as("silme, karşı tarafın sohbet geçmişini de götürmemeli")
			.isEqualTo(2L);
	}

	@Test
	void deletingAccount_removesPersonalContent() {
		AppUser client = createUser("icerik_sahibi@test.com", UserRole.CLIENT);
		profileFor(client, null);
		Long clientId = client.getId();

		actingAs(client);
		chatService.getMyConversations(PageRequest.of(0, 10)); // bağlamı ısıt
		entityManager.flush();

		actingAs(client);
		accountDeletionService.deleteMyAccount();
		entityManager.flush();
		entityManager.clear();

		assertThat(countWhere("SELECT COUNT(m) FROM Measurement m WHERE m.user.id = :id", clientId))
			.as("ölçümler silinmeli")
			.isZero();
		assertThat(countWhere("SELECT COUNT(b) FROM TrainingBlock b WHERE b.client.id = :id", clientId))
			.as("antrenman programları silinmeli")
			.isZero();
		assertThat(countWhere("SELECT COUNT(p) FROM DietProgram p WHERE p.owner.id = :id", clientId))
			.as("diyet programları silinmeli")
			.isZero();
		assertThat(countWhere("SELECT COUNT(w) FROM WaterIntake w WHERE w.user.id = :id", clientId))
			.as("su takibi silinmeli")
			.isZero();
	}

}
