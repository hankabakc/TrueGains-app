package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.UserRecipeIngredient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface UserRecipeIngredientRepository extends JpaRepository<UserRecipeIngredient, Long> {

	List<UserRecipeIngredient> findByUserRecipeId(Long userRecipeId);

}
