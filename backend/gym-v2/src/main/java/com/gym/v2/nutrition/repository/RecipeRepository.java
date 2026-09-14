package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.Recipe;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RecipeRepository extends JpaRepository<Recipe, Long> {

	@Query("SELECT r FROM Recipe r WHERE LOWER(r.name) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(r.category) LIKE LOWER(CONCAT('%', :query, '%'))")
	List<Recipe> searchRecipes(@Param("query") String query);

	List<Recipe> findByCategory(@Param("category") String category);

	boolean existsByName(String name);

}
