package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.CustomGlass;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CustomGlassRepository extends JpaRepository<CustomGlass, Long> {

	List<CustomGlass> findByUserIdOrderByCreatedAtAsc(Long userId);

	long countByUserId(Long userId);

}
