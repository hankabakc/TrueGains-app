package com.gym.v2.nutrition.repository;

import com.gym.v2.nutrition.entity.WaterIntake;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

/**
 * Su Tüketimi Veri Erişim Katmanı (WaterIntakeRepository)
 */
@Repository
public interface WaterIntakeRepository extends JpaRepository<WaterIntake, Long> {

	List<WaterIntake> findByUserIdAndIntakeDate(Long userId, LocalDate date);

	@Query("SELECT SUM(wi.amountMl) FROM WaterIntake wi WHERE wi.user.id = :userId AND wi.intakeDate = :date")
	Integer getTotalIntakeByDate(@Param("userId") Long userId, @Param("date") LocalDate date);

	@Query("SELECT wi.intakeDate as date, SUM(wi.amountMl) as total FROM WaterIntake wi "
			+ "WHERE wi.user.id = :userId AND wi.intakeDate BETWEEN :startDate AND :endDate GROUP BY wi.intakeDate")
	List<Object[]> getDailyTotalsByDateRange(@Param("userId") Long userId, @Param("startDate") LocalDate startDate,
			@Param("endDate") LocalDate endDate);

}
