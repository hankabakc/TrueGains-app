package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.Meal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MealRepository extends JpaRepository<Meal, Long> {

	/**
	 * Belirli bir diyet gününe ait tüm öğünleri sırasıyla bulur.
	 */
	List<Meal> findByDietDayIdOrderByOrderIndexAsc(Long dietDayId);

}
