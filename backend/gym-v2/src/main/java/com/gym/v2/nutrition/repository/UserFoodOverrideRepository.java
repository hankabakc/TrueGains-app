package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.UserFoodOverride;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserFoodOverrideRepository extends JpaRepository<UserFoodOverride, Long> {

	/**
	 * Belirli bir kullanıcının tüm değer ezmelerini bulur.
	 */
	java.util.List<UserFoodOverride> findAllByUserId(Long userId);

	Optional<UserFoodOverride> findByUserIdAndFoodId(Long userId, Long foodId);

	/**
	 * Verilen besinler için kullanıcının ezme kayıtlarını tek sorguda getirir. Liste
	 * uçlarında besin başına sorgu atılmasını önler.
	 */
	java.util.List<UserFoodOverride> findByUserIdAndFoodIdIn(Long userId, java.util.Collection<Long> foodIds);

}
