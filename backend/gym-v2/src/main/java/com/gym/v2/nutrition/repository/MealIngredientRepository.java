package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.MealIngredient;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MealIngredientRepository extends JpaRepository<MealIngredient, Long> {

	/**
	 * Belirli bir öğüne ait tüm besinleri (içerikleri) bulur.
	 */
	List<MealIngredient> findByMealId(Long mealId);

	/**
	 * Kullanıcının son yediği besinleri (benzersiz olarak) bulur. En son eklenen
	 * ingrediente göre sıralar.
	 */
	@Query("SELECT mi.food.id, mi.meal.mealType FROM MealIngredient mi "
			+ "WHERE mi.meal.dietDay.dietProgram.owner.id = :userId " + "AND mi.food IS NOT NULL "
			+ "GROUP BY mi.food.id, mi.meal.mealType " + "ORDER BY MAX(mi.id) DESC")
	List<Object[]> findRecentFoodsWithMealTypeByUserId(@Param("userId") Long userId, Pageable pageable);

}
