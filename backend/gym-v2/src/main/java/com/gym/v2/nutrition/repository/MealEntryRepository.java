package com.gym.v2.nutrition.repository;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.nutrition.entity.MealEntry;
import com.gym.v2.nutrition.entity.MealType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

/**
 * MealEntry için veritabanı erişim katmanı. Bulgu #1 (Instant Geçişi) kapsamında
 * güncellendi.
 */
@Repository
public interface MealEntryRepository extends JpaRepository<MealEntry, Long> {

	@Query("SELECT m FROM MealEntry m WHERE m.client.id = :clientId AND m.takenDatetime >= :start AND m.takenDatetime < :end")
	List<MealEntry> findDailyLogs(@Param("clientId") Long clientId, @Param("start") Instant start,
			@Param("end") Instant end);

	@Query("SELECT m FROM MealEntry m WHERE m.client = :client AND m.mealType = :type AND m.takenDatetime >= :start AND m.takenDatetime < :end")
	Optional<MealEntry> findByClientAndMealTypeAndDateRange(@Param("client") AppUser client,
			@Param("type") MealType type, @Param("start") Instant start, @Param("end") Instant end);

	// Adım 2.3: Performance Analytics - Native SQL Aggregations
	@Query(value = "SELECT CAST(m.taken_datetime AT TIME ZONE 'UTC' AS DATE) as entryDate, "
			+ "COALESCE(SUM(m.protein), 0), COALESCE(SUM(m.carbs), 0), COALESCE(SUM(m.fat), 0), "
			+ "COALESCE(SUM(m.calories), 0), COALESCE(SUM(m.sugar), 0), COALESCE(SUM(m.fiber), 0), "
			+ "COALESCE(SUM(m.sodium), 0), COALESCE(SUM(m.potassium), 0), COALESCE(SUM(m.cholesterol), 0) "
			+ "FROM meal_entry m WHERE m.client_id = :clientId AND m.taken_datetime >= :start AND m.taken_datetime < :end "
			+ "GROUP BY entryDate ORDER BY entryDate", nativeQuery = true)
	List<Object[]> findDailyNutrientTotals(@Param("clientId") Long clientId, @Param("start") Instant start,
			@Param("end") Instant end);

	@Query(value = "SELECT CAST(m.taken_datetime AT TIME ZONE 'UTC' AS DATE) as entryDate, m.meal_type, "
			+ "COALESCE(SUM(m.calories), 0) "
			+ "FROM meal_entry m WHERE m.client_id = :clientId AND m.taken_datetime >= :start AND m.taken_datetime < :end "
			+ "GROUP BY entryDate, m.meal_type", nativeQuery = true)
	List<Object[]> findDailyMealBreakdown(@Param("clientId") Long clientId, @Param("start") Instant start,
			@Param("end") Instant end);

}
