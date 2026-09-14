package com.gym.v2.finance;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.finance.entity.ClientSubscription;
import com.gym.v2.finance.entity.SubscriptionPackage;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import com.gym.v2.finance.repository.SubscriptionPackageRepository;
import com.gym.v2.finance.service.FinanceService;
import com.gym.v2.support.IntegrationTestBase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.TestPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Abonelik bitiş görevinin sorgu maliyeti.
 * <p>
 * Görev zamanlanmış ve tek bir {@code @Transactional} içinde koşuyor. Maliyet süresi
 * dolan müşteri sayısıyla büyürse, ayın aynı gününde biten yüzlerce abonelik tek işlemde
 * binlerce sorgu üretir ve bağlantıyı o süre boyunca tutar — yavaşlayan yalnızca görev
 * değil, o sırada gelen normal isteklerdir.
 * </p>
 */
@TestPropertySource(properties = "spring.jpa.properties.hibernate.generate_statistics=true")
class SubscriptionExpiryQueryCountIT extends IntegrationTestBase {

	@Autowired
	private FinanceService financeService;

	@Autowired
	private ClientSubscriptionRepository subscriptionRepository;

	@Autowired
	private SubscriptionPackageRepository packageRepository;

	@PersistenceContext
	private EntityManager entityManager;

	private Statistics statistics() {
		return entityManager.getEntityManagerFactory().unwrap(SessionFactory.class).getStatistics();
	}

	private SubscriptionPackage newPackage(AppUser coach, String name) {
		SubscriptionPackage pkg = new SubscriptionPackage();
		pkg.setName(name);
		pkg.setPrice(new BigDecimal("100"));
		pkg.setDurationDays(30);
		pkg.setCoachId(coach.getId());
		return packageRepository.saveAndFlush(pkg);
	}

	/** {@code count} adet müşteri açar, her birine süresi dolmuş aktif abonelik verir. */
	private void seedExpiredSubscriptions(String prefix, int count) {
		AppUser coach = createUser(prefix + "_coach@test.com", UserRole.COACH);
		SubscriptionPackage pkg = newPackage(coach, prefix + " paketi");

		for (int i = 0; i < count; i++) {
			AppUser client = createUser(prefix + "_client" + i + "@test.com", UserRole.CLIENT);
			ClientSubscription sub = new ClientSubscription();
			sub.setClient(client);
			sub.setCoach(coach);
			sub.setPkg(pkg);
			sub.setStartDate(LocalDate.now().minusDays(60));
			sub.setEndDate(LocalDate.now().minusDays(1));
			sub.setIsActive(true);
			subscriptionRepository.saveAndFlush(sub);
		}
	}

	private long expireAndCountQueries() {
		entityManager.flush();
		entityManager.clear();
		statistics().clear();

		financeService.expireSubscriptions();

		return statistics().getPrepareStatementCount();
	}

	@Test
	void expireSubscriptions_onlyTheUpdateScalesWithClientCount() {
		seedExpiredSubscriptions("az", 1);
		long queriesForOne = expireAndCountQueries();

		seedExpiredSubscriptions("cok", 4);
		long queriesForFour = expireAndCountQueries();

		// Sabit eşik yerine iki veri boyutu karşılaştırılıyor (sabit sayı her yapı
		// değişikliğinde kırılır ve yanlış şeyi ölçer).
		//
		// Sıfır büyüme beklenmiyor: premium'u düşen her kullanıcı için bir UPDATE
		// gerekiyor ve yazma satır sayısıyla büyür. Beklenen, **okumaların sabit
		// kalması** — yani müşteri başına en fazla 1 ifade. Düzeltmeden önce müşteri
		// başına 5 ifade vardı (sayım + kullanıcı bul + kaydet + profil bul + kaydet);
		// her SELECT toplu hâle getirildi.
		long extraClients = 3;
		long growthPerClient = (queriesForFour - queriesForOne) / extraClients;

		assertThat(growthPerClient).isLessThanOrEqualTo(1);
	}

	@Test
	void expireSubscriptions_stillDeactivatesEverySubscription() {
		// Sorgu azaltmanın klasik bedeli sessizce iş atlamaktır: dördü de kapanmalı.
		seedExpiredSubscriptions("veri", 4);

		int affected = financeService.expireSubscriptions();

		assertThat(affected).isEqualTo(4);
		assertThat(subscriptionRepository.findByIsActiveTrueAndEndDateBefore(LocalDate.now())).isEmpty();
	}

}
