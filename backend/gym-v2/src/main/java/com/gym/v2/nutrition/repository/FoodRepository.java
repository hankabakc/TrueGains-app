package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.Food;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FoodRepository extends JpaRepository<Food, Long> {

	/**
	 * Görünürlük scope'lu arama: Global besinler VEYA kullanıcının erişebildiği
	 * creatorId'ler.
	 */
	@Query("SELECT f FROM Food f WHERE (f.isGlobal = true OR f.creatorId IN :creatorIds) "
			+ "AND (f.name ILIKE CONCAT('%', :query, '%') OR f.brand ILIKE CONCAT('%', :query, '%')) "
			+ "ORDER BY f.name ASC")
	List<Food> searchVisible(@Param("query") String query, @Param("creatorIds") List<Long> creatorIds,
			Pageable pageable);

	/**
	 * Oluşturan kullanıcıya göre besin sayısını döner (soft limit kontrolü).
	 */
	long countByCreatorId(Long creatorId);

	/**
	 * Kullanıcının kendi oluşturduğu özel besinleri tarihe göre azalan sırayla getirir.
	 */
	List<Food> findByCreatorIdOrderByCreatedAtDesc(Long creatorId);

	/**
	 * Barkoda göre besin bulur.
	 */
	java.util.Optional<Food> findByBarcode(String barcode);

	java.util.Optional<Food> findByName(String name);

}
