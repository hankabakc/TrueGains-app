package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.MealTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MealTemplateRepository extends JpaRepository<MealTemplate, Long> {

	List<MealTemplate> findAllByOwnerId(Long ownerId);

	Optional<MealTemplate> findByIdAndOwnerId(Long id, Long ownerId);

}
