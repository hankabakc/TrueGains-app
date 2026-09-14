package com.gym.v2.admin.repository;

import com.gym.v2.admin.dto.AdminPaymentRowProjection;
import com.gym.v2.admin.dto.AdminRevenueProjection;
import com.gym.v2.finance.entity.PaymentTransaction;
import java.time.Instant;
import java.time.LocalDate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

/**
 * Gelir ve odeme sorgulari. Salt okunur arayuz; panel para hareketine dokunmaz.
 * <p>
 * Zaman esikleri disaridan parametre olarak geliyor ({@code Clock}), sorgu icinde
 * {@code NOW()} yok - test edilebilirlik icin.
 * </p>
 */
public interface AdminFinanceRepository extends Repository<PaymentTransaction, Long> {

	// failedPayments yalnızca FAILED sayar: FinanceService her ödeme başlangıcında
	// PENDING
	// satırı açıyor; yarıda bırakılan ödeme başarısız ödeme değildir.
	@Query(value = """
			SELECT
			  COALESCE((SELECT SUM(amount) FROM payment_transaction
			            WHERE status = 'SUCCESS' AND transaction_date >= :since24h), 0) AS revenueToday,
			  COALESCE((SELECT SUM(amount) FROM payment_transaction
			            WHERE status = 'SUCCESS' AND transaction_date >= :since7d), 0) AS revenue7d,
			  COALESCE((SELECT SUM(amount) FROM payment_transaction
			            WHERE status = 'SUCCESS' AND transaction_date >= :since30d), 0) AS revenue30d,
			  COALESCE((SELECT SUM(amount) FROM payment_transaction
			            WHERE status = 'SUCCESS'), 0) AS revenueTotal,
			  (SELECT COUNT(*) FROM payment_transaction WHERE status = 'SUCCESS') AS successfulPayments,
			  (SELECT COUNT(*) FROM payment_transaction WHERE status = 'FAILED') AS failedPayments,
			  (SELECT COUNT(*) FROM client_subscription
			     WHERE is_active = true AND end_date >= :today) AS activeSubscriptions,
			  (SELECT COUNT(*) FROM client_subscription
			     WHERE is_active = true AND end_date >= :today AND end_date < :in7d) AS expiringIn7d
			""", nativeQuery = true)
	AdminRevenueProjection loadSummary(@Param("since24h") Instant since24h, @Param("since7d") Instant since7d,
			@Param("since30d") Instant since30d, @Param("today") LocalDate today, @Param("in7d") LocalDate in7d);

	/**
	 * {@code transaction_date} NULL olabilir ({@code PaymentTransaction.java:29}); süzgeç
	 * verilmemişken tarihsiz ödemeler listeden DÜŞMEMELİ. Aralık koşulu bu yüzden
	 * {@code hasRange} bayrağına bağlı; {@code since}/{@code until} hiçbir zaman null
	 * gelmez. E-posta koşulu sayım sorgusunda da var, bu yüzden sayım sorgusu da
	 * app_user'a bağlanıyor.
	 */
	@Query(value = """
			SELECT p.id AS id, u.email AS clientEmail, p.amount AS amount, p.status AS status,
			       p.transaction_date AS transactionDate, sp.name AS packageName
			FROM payment_transaction p
			LEFT JOIN app_user u ON u.id = p.client_id
			LEFT JOIN subscription_package sp ON sp.id = p.package_id
			WHERE (CAST(:status AS text) IS NULL OR p.status = CAST(:status AS text))
			  AND (CAST(:email AS text) IS NULL
			       OR LOWER(u.email) LIKE LOWER('%' || CAST(:email AS text) || '%'))
			  AND (CAST(:hasRange AS boolean) = false
			       OR (p.transaction_date >= :since AND p.transaction_date < :until))
			ORDER BY p.transaction_date DESC NULLS LAST, p.id DESC
			""", countQuery = """
			SELECT COUNT(*) FROM payment_transaction p
			LEFT JOIN app_user u ON u.id = p.client_id
			WHERE (CAST(:status AS text) IS NULL OR p.status = CAST(:status AS text))
			  AND (CAST(:email AS text) IS NULL
			       OR LOWER(u.email) LIKE LOWER('%' || CAST(:email AS text) || '%'))
			  AND (CAST(:hasRange AS boolean) = false
			       OR (p.transaction_date >= :since AND p.transaction_date < :until))
			""", nativeQuery = true)
	Page<AdminPaymentRowProjection> listPayments(@Param("status") String status, @Param("email") String email,
			@Param("hasRange") boolean hasRange, @Param("since") Instant since, @Param("until") Instant until,
			Pageable pageable);

}
