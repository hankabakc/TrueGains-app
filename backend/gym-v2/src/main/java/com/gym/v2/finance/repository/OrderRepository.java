package com.gym.v2.finance.repository;

import com.gym.v2.finance.entity.OrderStatus;
import com.gym.v2.finance.entity.Order;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

/**
 * Sipariş İşlemleri için Spring Data JPA Repository Arayüzü
 */
public interface OrderRepository extends JpaRepository<Order, Long> {

	Optional<Order> findByCheckoutSessionId(String checkoutSessionId);

	/**
	 * Siparişi yalnızca hâlâ {@code PENDING} ise hedef duruma taşır ve etkilenen satır
	 * sayısını döner.
	 * <p>
	 * Mükerrerlik kontrolü daha önce "oku, kontrol et, yaz" şeklindeydi ve arada kilit
	 * yoktu: ödeme sağlayıcıları teslim garantisi için webhook'u tekrarladığından iki
	 * bildirim aynı anda gelip ikisi de {@code PENDING} okuyabiliyor, abonelik iki kez
	 * uzatılıyordu. Durum geçişi tek atomik {@code UPDATE} ile yapıldığında yarışı
	 * veritabanı çözer: yalnızca bir çağrı 1 döner.
	 * </p>
	 */
	@Modifying
	@Query("UPDATE Order o SET o.status = :target WHERE o.id = :id AND o.status = com.gym.v2.finance.entity.OrderStatus.PENDING")
	int markIfPending(@Param("id") Long id, @Param("target") OrderStatus target);

}
