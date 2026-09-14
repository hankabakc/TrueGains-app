package com.gym.v2.finance.repository;

import com.gym.v2.finance.entity.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, Long> {

	@Query("SELECT t FROM PaymentTransaction t JOIN FETCH t.pkg"
			+ " WHERE t.client.id = :clientId ORDER BY t.transactionDate DESC")
	List<PaymentTransaction> findByClientIdWithPkg(@Param("clientId") Long clientId);

	List<PaymentTransaction> findByClientIdOrderByTransactionDateDesc(Long clientId);

	@Query("SELECT COALESCE(SUM(t.amount), 0) FROM PaymentTransaction t"
			+ " WHERE t.pkg.coachId = :coachId AND t.status = 'SUCCESS'" + " AND t.transactionDate >= :startOfMonth")
	java.math.BigDecimal sumCoachEarningsSince(@Param("coachId") Long coachId,
			@Param("startOfMonth") java.time.Instant startOfMonth);

}
