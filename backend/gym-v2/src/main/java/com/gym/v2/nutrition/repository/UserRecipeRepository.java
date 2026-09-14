package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.UserRecipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRecipeRepository extends JpaRepository<UserRecipe, Long> {

	List<UserRecipe> findAllByUserId(Long userId);

	@Query("SELECT ur FROM UserRecipe ur WHERE (ur.user.id = :userId) AND "
			+ "(LOWER(ur.name) LIKE LOWER(CONCAT('%', :query, '%')))")
	List<UserRecipe> searchUserRecipes(@Param("userId") Long userId, @Param("query") String query);

	Optional<UserRecipe> findFirstByUserIdAndOriginalRecipeId(Long userId, Long originalRecipeId);

	Optional<UserRecipe> findByIdAndUserId(Long id, Long userId);

}
