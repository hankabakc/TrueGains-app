package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.Food;
import com.gym.v2.nutrition.entity.MealItem;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

/**
 * MealItem için veritabanı erişim katmanı. Bulgu #1 (Instant Geçişi) kapsamında
 * güncellendi.
 */
@Repository
public interface MealItemRepository extends JpaRepository<MealItem, Long> {

	@Query("SELECT COALESCE(f.name, r.name), COUNT(mi), "
			+ "COALESCE(SUM(mi.calories), 0), COALESCE(SUM(mi.protein), 0), "
			+ "COALESCE(SUM(mi.carbs), 0), COALESCE(SUM(mi.fat), 0) " + "FROM MealItem mi " + "LEFT JOIN mi.food f "
			+ "LEFT JOIN mi.recipe r " + "WHERE mi.mealEntry.client.id = :clientId "
			+ "AND mi.mealEntry.takenDatetime >= :start AND mi.mealEntry.takenDatetime < :end "
			+ "GROUP BY COALESCE(f.name, r.name) " + "ORDER BY COUNT(mi) DESC")
	List<Object[]> findFoodFrequency(@Param("clientId") Long clientId, @Param("start") Instant start,
			@Param("end") Instant end);

	@Query("SELECT mi.food FROM MealItem mi " + "WHERE mi.mealEntry.client.id = :clientId " + "AND mi.food IS NOT NULL "
			+ "GROUP BY mi.food " + "ORDER BY MAX(mi.mealEntry.takenDatetime) DESC")
	List<Food> findRecentFoods(@Param("clientId") Long clientId, Pageable pageable);

}
