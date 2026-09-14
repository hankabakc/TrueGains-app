package com.gym.v2.finance.repository;

import com.gym.v2.finance.entity.ClientSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.List;
import java.time.LocalDate;

public interface ClientSubscriptionRepository extends JpaRepository<ClientSubscription, Long> {

	@Query("SELECT s FROM ClientSubscription s JOIN FETCH s.pkg JOIN FETCH s.client"
			+ " LEFT JOIN FETCH s.coach WHERE s.client.id = :clientId AND s.isActive = true")
	Optional<ClientSubscription> findActiveSubscriptionByClientId(@Param("clientId") Long clientId);

	@Query("SELECT s FROM ClientSubscription s WHERE s.client.id = :clientId")
	List<ClientSubscription> findByClientId(@Param("clientId") Long clientId);

	List<ClientSubscription> findByIsActiveTrueAndEndDateBefore(LocalDate date);

	@Query("SELECT COUNT(s) FROM ClientSubscription s WHERE s.client.id = :clientId AND s.isActive = true AND s.endDate >= :today")
	long countActiveByClientId(@Param("clientId") Long clientId, @Param("today") LocalDate today);

	/**
	 * Birden çok müşterinin aktif abonelik sayısını tek sorguda verir.
	 * <p>
	 * Abonelik bitiş görevi bunu müşteri başına ayrı ayrı soruyordu; aynı gün biten
	 * abonelik sayısı arttıkça sorgu sayısı doğrusal büyüyordu. Aktif aboneliği kalmayan
	 * müşteri sonuçta <b>hiç görünmez</b> (COUNT 0 satır üretmez), çağıran taraf eksik
	 * anahtarları "sıfır" olarak yorumlar.
	 * </p>
	 */
	@Query("SELECT s.client.id, COUNT(s) FROM ClientSubscription s WHERE s.client.id IN :clientIds "
			+ "AND s.isActive = true AND s.endDate >= :today GROUP BY s.client.id")
	List<Object[]> countActiveByClientIds(@Param("clientIds") List<Long> clientIds, @Param("today") LocalDate today);

	@Query("SELECT COUNT(s) FROM ClientSubscription s WHERE s.pkg.id = :packageId AND s.isActive = true AND s.endDate >= :today")
	long countActiveByPackageId(@Param("packageId") Long packageId, @Param("today") LocalDate today);

	@Query("SELECT s.pkg.id, COUNT(s) FROM ClientSubscription s WHERE s.pkg.id IN :ids AND s.isActive = true AND s.endDate >= :today GROUP BY s.pkg.id")
	List<Object[]> countActiveByPackageIds(@Param("ids") List<Long> ids, @Param("today") LocalDate today);

}
