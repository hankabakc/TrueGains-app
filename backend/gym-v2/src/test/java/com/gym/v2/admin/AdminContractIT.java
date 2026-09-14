package com.gym.v2.admin;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.social.entity.ReportReason;
import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import com.gym.v2.core.entity.AuditLog;
import com.gym.v2.core.repository.AuditLogRepository;
import com.gym.v2.finance.entity.PaymentTransaction;
import com.gym.v2.finance.repository.PaymentTransactionRepository;
import com.gym.v2.social.repository.UserReportRepository;
import com.gym.v2.support.IntegrationTestBase;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Yönetim uçlarının <b>gerçek veriyle</b> sözleşmesi.
 * <p>
 * {@code AdminSecurityIT} yetkiyi kilitliyor ama tabloların boş olduğu durumu ölçüyor.
 * Boş tabloda geçen bir sorgu dolu tabloda patlayabilir: birleştirme (join) hatası,
 * şifreli alanın çözülememesi, sayfalama sayacının yanlış olması. Bu sınıf kayıt
 * tohumlayıp dönen JSON'un alanlarını tek tek doğruluyor.
 * </p>
 * <p>
 * Kimlik doğrulama <b>gerçek JWT</b> ile yapılıyor ({@code bearerTokenFor}), yani
 * güvenlik zinciri de dahil uçtan uca sürülüyor.
 * </p>
 */
class AdminContractIT extends IntegrationTestBase {

	@Autowired
	private AuditLogRepository auditLogRepository;

	@Autowired
	private UserReportRepository userReportRepository;

	@Autowired
	private PaymentTransactionRepository paymentTransactionRepository;

	private String adminToken;

	private Long coachUserId;

	private Long clientUserId;

	@BeforeEach
	void seed() {
		AppUser admin = createUser("yonetici@test.com", UserRole.ADMIN);
		adminToken = bearerTokenFor(admin);

		AppUser coachUser = createUser("antrenor@test.com", UserRole.COACH);
		coachUserId = coachUser.getId();

		// CoachEntity @MapsId kullaniyor: kimlik user iliskisinden geliyor,
		// yalnizca userId atamak yetmiyor.
		CoachEntity coach = new CoachEntity();
		coach.setUser(coachUser);
		coach.setFullName("Antrenör Adı");
		coach.setSpecialization("Fitness,Crossfit");
		coach.setProvince("İstanbul");
		coach.setDistrict("Kadıköy");
		coach.setExperienceYears(8);
		coachRepository.saveAndFlush(coach);

		AppUser clientUser = createUser("sporcu@test.com", UserRole.CLIENT);
		clientUserId = clientUser.getId();

		ClientEntity client = new ClientEntity();
		client.setUser(clientUser);
		client.setFullName("Sporcu Adı");
		client.setCoachId(coachUserId);
		clientRepository.saveAndFlush(client);

		userReportRepository.saveAndFlush(new UserReport(clientUserId, coachUserId, ReportReason.SCAM,
				"şüpheli davranış", Instant.parse("2026-09-01T10:00:00Z")));

		PaymentTransaction payment = new PaymentTransaction();
		payment.setClient(clientUser);
		payment.setAmount(new BigDecimal("750.00"));
		payment.setStatus("SUCCESS");
		payment.setTransactionDate(Instant.parse("2026-09-03T09:00:00Z"));
		paymentTransactionRepository.saveAndFlush(payment);
	}

	private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder authed(String path) {
		return get(path).header(HttpHeaders.AUTHORIZATION, adminToken);
	}

	@Test
	void overview_countsSeededUsers() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/overview"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalUsers").value(3))
			.andExpect(jsonPath("$.data.clientCount").value(1))
			.andExpect(jsonPath("$.data.coachCount").value(1))
			.andExpect(jsonPath("$.data.pairedClients").value(1));
	}

	/**
	 * İsimler AES şifreli saklanıyor; listede <b>çözülmüş</b> gelmeli. Çözme adımı
	 * atlanırsa ekranda base64 ciphertext görünür.
	 */
	@Test
	void users_listDecryptsNamesAndJoinsCoachAndClientTables() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users?query=antrenor"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].email").value("antrenor@test.com"))
			.andExpect(jsonPath("$.data.content[0].fullName").value("Antrenör Adı"))
			.andExpect(jsonPath("$.data.content[0].role").value("COACH"))
			.andExpect(jsonPath("$.data.content[0].active").value(true));

		mockMvc.perform(authed("/api/v1/admin/users?query=sporcu"))
			.andExpect(jsonPath("$.data.content[0].fullName").value("Sporcu Adı"));
	}

	@Test
	void users_roleFilterNarrowsResult() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users?role=COACH"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].role").value("COACH"));
	}

	@Test
	void userDetail_returnsCoachSpecificFields() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users/" + coachUserId))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.fullName").value("Antrenör Adı"))
			.andExpect(jsonPath("$.data.province").value("İstanbul"))
			.andExpect(jsonPath("$.data.district").value("Kadıköy"))
			.andExpect(jsonPath("$.data.experienceYears").value(8))
			.andExpect(jsonPath("$.data.specialization").value("Fitness,Crossfit"));
	}

	@Test
	void userDetail_returnsClientSpecificFields() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users/" + clientUserId))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.coachId").value(coachUserId))
			.andExpect(jsonPath("$.data.activeSubscriptions").value(0));
	}

	/** Panelin tek yazma işlemi: durum değişmeli ve yanıt yeni hâli döndürmeli. */
	@Test
	void setActive_flipsAccountStatus() throws Exception {
		mockMvc
			.perform(patch("/api/v1/admin/users/" + clientUserId + "/active").param("value", "false")
				.header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
					.csrf()))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.active").value(false));

		mockMvc.perform(authed("/api/v1/admin/users?active=false"))
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].email").value("sporcu@test.com"));
	}

	/** Ciro yalnizca SUCCESS islemleri sayar; toplam tohumlanan odemeyi yansitmali. */
	@Test
	void revenue_sumsOnlySuccessfulPayments() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/finance/revenue"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.revenueTotal").value(750.00))
			.andExpect(jsonPath("$.data.successfulPayments").value(1))
			.andExpect(jsonPath("$.data.failedPayments").value(0))
			.andExpect(jsonPath("$.data.activeSubscriptions").value(0))
			.andExpect(jsonPath("$.data.expiringIn7d").value(0));
	}

	/**
	 * Şikâyet kuyruğu: şikâyet eden ve edilenin e-postası TEK sorguda gelmeli (N+1 yok)
	 * ve açıklama şifreli saklandığı için çözülmüş dönmeli.
	 */
	@Test
	void reports_joinEmailsAndDecryptDescription() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/reports?status=PENDING"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].reason").value("SCAM"))
			.andExpect(jsonPath("$.data.content[0].status").value("PENDING"))
			.andExpect(jsonPath("$.data.content[0].description").value("şüpheli davranış"))
			.andExpect(jsonPath("$.data.content[0].reporterEmail").value("sporcu@test.com"))
			.andExpect(jsonPath("$.data.content[0].reportedEmail").value("antrenor@test.com"))
			.andExpect(jsonPath("$.data.content[0].reportedUserPendingCount").value(1));
	}

	@Test
	void resolveReport_recordsDecisionAndRemovesItFromPendingQueue() throws Exception {
		Long reportId = userReportRepository.findAll().get(0).getId();

		mockMvc
			.perform(patch("/api/v1/admin/reports/" + reportId).contentType(MediaType.APPLICATION_JSON)
				.content("{\"decision\":\"ACTIONED\",\"note\":\"hesap kapatıldı\"}")
				.header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
					.csrf()))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.status").value("ACTIONED"))
			.andExpect(jsonPath("$.data.reviewedBy").value("yonetici@test.com"))
			.andExpect(jsonPath("$.data.resolutionNote").value("hesap kapatıldı"));

		mockMvc.perform(authed("/api/v1/admin/reports?status=PENDING"))
			.andExpect(jsonPath("$.data.totalElements").value(0));

		// Alan gönderilmedi: hesap durumuna DOKUNULMAMALI. Bu kontrol olmadan
		// kontrolördeki null indirgemesi korumasız kalıyor.
		mockMvc.perform(authed("/api/v1/admin/users/" + coachUserId)).andExpect(jsonPath("$.data.active").value(true));
	}

	/** PENDING bir karar değil; kabul edilseydi işlemi geri almanın yolu olurdu. */
	@Test
	void resolveReport_withPendingDecision_isRejected() throws Exception {
		Long reportId = userReportRepository.findAll().get(0).getId();

		mockMvc
			.perform(patch("/api/v1/admin/reports/" + reportId).contentType(MediaType.APPLICATION_JSON)
				.content("{\"decision\":\"PENDING\"}")
				.header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
					.csrf()))
			.andExpect(status().isBadRequest());
	}

	@Test
	void resolveReport_withSuspendReportedUser_suspendsUserAtomically() throws Exception {
		Long reportId = userReportRepository.findAll().get(0).getId();

		mockMvc
			.perform(patch("/api/v1/admin/reports/" + reportId).contentType(MediaType.APPLICATION_JSON)
				.content("{\"decision\":\"ACTIONED\",\"note\":\"kural ihlali\",\"suspendReportedUser\":true}")
				.header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
					.csrf()))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.status").value("ACTIONED"));

		mockMvc.perform(authed("/api/v1/admin/users/" + coachUserId))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.active").value(false));
	}

	@Test
	void reports_filterByReportedUserId_returnsOnlyMatchingReports() throws Exception {
		userReportRepository.saveAndFlush(new UserReport(coachUserId, clientUserId, ReportReason.OTHER, "başka şikayet",
				Instant.parse("2026-09-02T10:00:00Z")));

		mockMvc.perform(authed("/api/v1/admin/reports?reportedUserId=" + coachUserId))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].reportedUserId").value(coachUserId));

		mockMvc.perform(authed("/api/v1/admin/reports?reportedUserId=" + clientUserId))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].reportedUserId").value(clientUserId));

		mockMvc.perform(authed("/api/v1/admin/reports?reportedUserId=999999"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(0));
	}

	/**
	 * Yönetim erişimleri denetim defterine düşüyor; defter ekranı da onu okuyor. Bu test
	 * aynı zamanda {@code AdminAuditInterceptor}'ın gerçekten çalıştığını kanıtlıyor.
	 */
	@Test
	void audit_recordsAdminAccessAndListsIt() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/overview")).andExpect(status().isOk());

		mockMvc.perform(authed("/api/v1/admin/audit"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.content").isArray());

		mockMvc.perform(authed("/api/v1/admin/audit/actions")).andExpect(status().isOk());

		// E-POSTA FILTRELI dal ayrica surulmeli: filtre null iken PostgreSQL
		// LOWER(:param) parametresinin tipini cikaramayip bytea sayiyordu
		// ("function lower(bytea) does not exist"). Iki dal da calismali.
		mockMvc.perform(authed("/api/v1/admin/audit?email=yonetici"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.content").isArray());

		mockMvc.perform(authed("/api/v1/admin/audit?action=ADMIN_ACCESS&email=YONETICI"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.content").isArray());
	}

	/** Sentry yapılandırılmamışken uç hata vermemeli; panel çalışmaya devam etmeli. */
	@Test
	void errors_withoutSentryConfiguration_reportsNotConfiguredInsteadOfFailing() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/errors"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.configured").value(false))
			.andExpect(jsonPath("$.data.issues").isArray());
	}

	/** İstemci sayfa boyunu istediği gibi büyütememeli. */
	@Test
	void users_pageSizeIsCappedServerSide() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users?size=100000"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.pageSize").value(100));
	}

	/**
	 * Odeme listesi projeksiyonu da TIMESTAMPTZ tasiyor; bos tabloda hic surulmedigi icin
	 * ayni "OffsetDateTime -> Instant" hatasi orada sessizce durabilirdi.
	 */
	@Test
	void payments_listReturnsRowsWithJoinedEmailAndTimestamp() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/finance/payments"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].clientEmail").value("sporcu@test.com"))
			.andExpect(jsonPath("$.data.content[0].amount").value(750.00))
			.andExpect(jsonPath("$.data.content[0].status").value("SUCCESS"))
			.andExpect(jsonPath("$.data.content[0].transactionDate").exists());
	}

	@Test
	void payments_statusFilterNarrowsResult() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/finance/payments?status=FAILED"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(0));
	}

	@Test
	void audit_dateRangeFilter_includesLowerBoundExcludesUpperBound() throws Exception {
		auditLogRepository.saveAndFlush(new AuditLog("TEST_RANGE", "aralik@test.com", "127.0.0.1", "icerde",
				Instant.parse("2026-09-06T15:30:00Z")));
		auditLogRepository.saveAndFlush(new AuditLog("TEST_RANGE", "aralik@test.com", "127.0.0.1", "disarida",
				Instant.parse("2026-09-06T17:30:00Z")));

		mockMvc.perform(authed("/api/v1/admin/audit?email=aralik@test.com"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(2));

		mockMvc
			.perform(authed(
					"/api/v1/admin/audit?email=aralik@test.com&from=2026-09-06T15:00:00Z&to=2026-09-06T16:00:00Z"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].details").value("icerde"));

		mockMvc
			.perform(authed(
					"/api/v1/admin/audit?email=aralik@test.com&from=2026-09-06T15:30:00Z&to=2026-09-06T17:30:00Z"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].details").value("icerde"));

		mockMvc.perform(authed("/api/v1/admin/audit?from=bozuk")).andExpect(status().isBadRequest());
	}

	@Test
	void payments_dateAndEmailFilters_keepUndatedPaymentsWhenUnfiltered() throws Exception {
		AppUser coachUser = userRepository.findById(coachUserId).orElseThrow();
		AppUser clientUser = userRepository.findById(clientUserId).orElseThrow();

		PaymentTransaction pFailed = new PaymentTransaction();
		pFailed.setClient(coachUser);
		pFailed.setAmount(new BigDecimal("300.00"));
		pFailed.setStatus("FAILED");
		pFailed.setTransactionDate(Instant.parse("2026-09-10T09:00:00Z"));
		paymentTransactionRepository.saveAndFlush(pFailed);

		PaymentTransaction pUndated = new PaymentTransaction();
		pUndated.setClient(clientUser);
		pUndated.setAmount(new BigDecimal("100.00"));
		pUndated.setStatus("PENDING");
		pUndated.setTransactionDate(null);
		paymentTransactionRepository.saveAndFlush(pUndated);

		mockMvc.perform(authed("/api/v1/admin/finance/payments"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(3));

		mockMvc.perform(authed("/api/v1/admin/finance/payments?from=2026-09-01T00:00:00Z&to=2026-09-05T00:00:00Z"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].clientEmail").value("sporcu@test.com"));

		mockMvc.perform(authed("/api/v1/admin/finance/payments?to=2026-09-05T00:00:00Z"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1));

		mockMvc.perform(authed("/api/v1/admin/finance/payments?email=antrenor"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(1))
			.andExpect(jsonPath("$.data.content[0].status").value("FAILED"));

		mockMvc
			.perform(authed(
					"/api/v1/admin/finance/payments?email=ANTRENOR&from=2026-09-01T00:00:00Z&to=2026-09-05T00:00:00Z"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.totalElements").value(0));
	}

	@Test
	void revenue_countsOnlyFailedPaymentsAsFailed() throws Exception {
		AppUser clientUser = userRepository.findById(clientUserId).orElseThrow();

		PaymentTransaction pPending = new PaymentTransaction();
		pPending.setClient(clientUser);
		pPending.setAmount(new BigDecimal("200.00"));
		pPending.setStatus("PENDING");
		pPending.setTransactionDate(Instant.parse("2026-09-04T09:00:00Z"));
		paymentTransactionRepository.saveAndFlush(pPending);

		PaymentTransaction pFailed = new PaymentTransaction();
		pFailed.setClient(clientUser);
		pFailed.setAmount(new BigDecimal("200.00"));
		pFailed.setStatus("FAILED");
		pFailed.setTransactionDate(Instant.parse("2026-09-04T10:00:00Z"));
		paymentTransactionRepository.saveAndFlush(pFailed);

		mockMvc.perform(authed("/api/v1/admin/finance/revenue"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.successfulPayments").value(1))
			.andExpect(jsonPath("$.data.failedPayments").value(1))
			.andExpect(jsonPath("$.data.revenueTotal").value(750.00));
	}

	@Test
	void users_export_appliesScreenFiltersAndDecryptsNames() throws Exception {
		mockMvc.perform(authed("/api/v1/admin/users/export?role=COACH"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.rowCount").value(1))
			.andExpect(jsonPath("$.data.csv")
				.value(containsString("\"antrenor@test.com\";\"Antrenör Adı\";\"Antrenör\";aktif;hayır;")))
			.andExpect(jsonPath("$.data.csv").value(not(containsString("sporcu@test.com"))));

		mockMvc.perform(authed("/api/v1/admin/users/export"))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.rowCount").value(3));
	}

	@Test
	void users_unlock_resetsCounterAndLockInDatabase() throws Exception {
		AppUser clientUser = userRepository.findById(clientUserId).orElseThrow();
		clientUser.setFailedLoginAttempts(3);
		clientUser.setAccountLockedUntil(Instant.parse("2099-01-01T00:00:00Z"));
		userRepository.saveAndFlush(clientUser);

		mockMvc
			.perform(patch("/api/v1/admin/users/" + clientUserId + "/unlock")
				.header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(csrf()))
			.andExpect(status().isOk())
			.andExpect(jsonPath("$.data.failedLoginAttempts").value(0))
			.andExpect(jsonPath("$.data.active").value(true));

		AppUser refreshed = userRepository.findById(clientUserId).orElseThrow();
		assertThat(refreshed.getFailedLoginAttempts()).isZero();
		assertThat(refreshed.getAccountLockedUntil()).isNull();
	}

	@Test
	void users_unlock_unknownUser_returns404() throws Exception {
		mockMvc
			.perform(patch("/api/v1/admin/users/999999/unlock").header(HttpHeaders.AUTHORIZATION, adminToken)
				.with(csrf()))
			.andExpect(status().isNotFound());
	}

}
