package com.gym.v2.training.repository;

import com.gym.v2.training.entity.WeeklyProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface WeeklyProgressRepository extends JpaRepository<WeeklyProgress, Long> {

	Optional<WeeklyProgress> findByUserIdAndTrainingBlockIdAndWeekStartDate(Long userId, Long trainingBlockId,
			LocalDate weekStartDate);

	List<WeeklyProgress> findByUserIdOrderByWeekStartDateDesc(Long userId);

	List<WeeklyProgress> findByUserIdAndTrainingBlockIdOrderByWeekStartDateAsc(Long userId, Long trainingBlockId);

}
