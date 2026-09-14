package com.gym.v2.social;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.nutrition.service.DietTemplateService;
import com.gym.v2.social.dto.ConversationDTO;
import com.gym.v2.social.dto.SendMessageRequest;
import com.gym.v2.social.service.ChatService;
import com.gym.v2.support.IntegrationTestBase;
import com.gym.v2.training.service.ProgramAssignmentService;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.List;
import java.util.function.Supplier;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Koç atama ekranlarının ve sohbet gönderiminin sorgu maliyeti veriyle büyümemeli.
 * <p>
 * Sabit eşik yerine <b>büyüme</b> ölçülür: aynı iş az veriyle ve çok veriyle yapılıp
 * sorgu sayıları karşılaştırılır. Sabit sayı her değişiklikte kırılır ve yanlış şeyi
 * ölçer.
 * </p>
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class AssignmentAndChatQueryCountIT extends IntegrationTestBase {

	@Autowired
	private ProgramAssignmentService assignmentService;

	@Autowired
	private DietTemplateService dietTemplateService;

	@Autowired
	private ChatService chatService;

	@PersistenceContext
	private EntityManager entityManager;

	@AfterEach
	void clearSecurityContext() {
		SecurityContextHolder.clearContext();
	}

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	/**
	 * Yüklenen VARLIK sayısı. Sorgu sayısı bazı hataları göremez: tek bir sorgu binlerce
	 * satırı belleğe alabilir. "Saymak yerine listeyi yükleme" hatası ancak bu metrikle
	 * yakalanır.
	 */
	private long entityLoadCountFor(String email, Supplier<?> call) {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(email, null, List.of()));
		call.get();

		return statistics().getEntityLoadCount();
	}

	/** Ölçümden önce kalıcılık bağlamı boşaltılır; yoksa ikinci ölçüm bellekten okur. */
	private long queryCountFor(String email, Supplier<?> call) {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(email, null, List.of()));
		call.get();

		return statistics().getPrepareStatementCount();
	}

	private AppUser newStudentOf(AppUser coach, String email) {
		AppUser user = createUser(email, UserRole.CLIENT);
		ClientEntity profile = new ClientEntity();
		profile.setUser(user);
		profile.setFullName("Sporcu " + email);
		profile.setCoachId(coach.getId());
		clientRepository.saveAndFlush(profile);
		return user;
	}

	/** Koça bir diyet şablonu kurup verilen sayıda öğrenciye atar. */
	private void seedDietAssignments(AppUser coach, int studentCount, String prefix) {
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(coach.getEmail(), null, List.of()));
		Long templateId = dietTemplateService.createTemplate(prefix + "-sablon").id();

		for (int i = 0; i < studentCount; i++) {
			AppUser student = newStudentOf(coach, prefix + i + "@test.com");
			SecurityContextHolder.getContext()
				.setAuthentication(new UsernamePasswordAuthenticationToken(coach.getEmail(), null, List.of()));
			dietTemplateService.assignTemplateToClient(templateId, student.getId());
		}
		entityManager.flush();
	}

	@Test
	void coachAssignmentList_queryCountDoesNotGrowWithStudentCount() {
		AppUser lightCoach = createUser("qc_light_coach@test.com", UserRole.COACH);
		AppUser heavyCoach = createUser("qc_heavy_coach@test.com", UserRole.COACH);
		seedDietAssignments(lightCoach, 1, "qclight");
		seedDietAssignments(heavyCoach, 4, "qcheavy");

		long lightQueries = queryCountFor(lightCoach.getEmail(), () -> dietTemplateService.getCoachAssignments());
		long heavyQueries = queryCountFor(heavyCoach.getEmail(), () -> dietTemplateService.getCoachAssignments());

		assertThat(heavyQueries)
			.as("1 öğrenci %d sorgu, 4 öğrenci %d sorgu ürettiyse profil aramaları öğrenci başına yapılıyor",
					lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void coachAssignmentList_stillReturnsEveryStudent() {
		AppUser coach = createUser("qc_data_coach@test.com", UserRole.COACH);
		seedDietAssignments(coach, 3, "qcdata");

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(coach.getEmail(), null, List.of()));

		// Sorgu azaltmanın klasik bedeli sessizce veri kaybetmektir; sayı da isim de
		// durmalı.
		assertThat(dietTemplateService.getCoachAssignments()).hasSize(3);
	}

	@Test
	void trainingAssignmentScreen_queryCountDoesNotGrowWithStudentCount() {
		AppUser lightCoach = createUser("qc_tr_light@test.com", UserRole.COACH);
		AppUser heavyCoach = createUser("qc_tr_heavy@test.com", UserRole.COACH);
		for (int i = 0; i < 1; i++) {
			newStudentOf(lightCoach, "trlight" + i + "@test.com");
		}
		for (int i = 0; i < 4; i++) {
			newStudentOf(heavyCoach, "trheavy" + i + "@test.com");
		}

		long lightQueries = queryCountFor(lightCoach.getEmail(),
				() -> assignmentService.getAssignedPrograms(lightCoach.getId()));
		long heavyQueries = queryCountFor(heavyCoach.getEmail(),
				() -> assignmentService.getAssignedPrograms(heavyCoach.getId()));

		assertThat(heavyQueries)
			.as("atama ekranının maliyeti öğrenci sayısıyla büyüyor (%d → %d)", lightQueries, heavyQueries)
			.isEqualTo(lightQueries);
	}

	@Test
	void sendMessage_doesNotLoadTheUnreadBacklogJustToCountIt() {
		AppUser coach = createUser("qc_msg_coach@test.com", UserRole.COACH);
		AppUser client = newStudentOf(coach, "qc_msg_client@test.com");

		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(client.getEmail(), null, List.of()));
		ConversationDTO conversation = chatService.initiateConversation(coach.getId());
		Long conversationId = conversation.id();

		long withEmptyHistory = entityLoadCountFor(coach.getEmail(),
				() -> chatService.sendMessage(new SendMessageRequest(conversationId, "ilk", null, null)));

		// Sporcunun okumadığı 10 mesaj biriksin.
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(coach.getEmail(), null, List.of()));
		for (int i = 0; i < 10; i++) {
			chatService.sendMessage(new SendMessageRequest(conversationId, "dolgu " + i, null, null));
		}

		long withUnreadHistory = entityLoadCountFor(coach.getEmail(),
				() -> chatService.sendMessage(new SendMessageRequest(conversationId, "son", null, null)));

		assertThat(withUnreadHistory)
			.as("okunmamış mesaj biriktikçe gönderim daha çok satır yüklüyor (%d → %d): "
					+ "okunmamışlar COUNT ile sayılmak yerine varlık olarak belleğe alınıyor", withEmptyHistory,
					withUnreadHistory)
			.isEqualTo(withEmptyHistory);
	}

}
