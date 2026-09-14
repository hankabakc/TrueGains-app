package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.WaterTarget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface WaterTargetRepository extends JpaRepository<WaterTarget, Long> {

	Optional<WaterTarget> findByUserIdAndValidToIsNull(Long userId);

	@Query("SELECT wt FROM WaterTarget wt WHERE wt.user.id = :userId " + "AND wt.validFrom <= :dateTime "
			+ "AND (wt.validTo IS NULL OR wt.validTo > :dateTime)")
	Optional<WaterTarget> findTargetAtDateTime(@Param("userId") Long userId, @Param("dateTime") LocalDateTime dateTime);

}
