package com.gym.v2.finance.repository;

import com.gym.v2.finance.entity.SubscriptionPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface SubscriptionPackageRepository extends JpaRepository<SubscriptionPackage, Long> {

	@Query("SELECT p FROM SubscriptionPackage p WHERE (p.coachId = :coachId OR p.coachId IS NULL) AND p.isActive = true ORDER BY p.price ASC")
	List<SubscriptionPackage> findAvailablePackages(@Param("coachId") Long coachId);

	List<SubscriptionPackage> findByCoachIdAndIsActiveTrue(Long coachId);

}
