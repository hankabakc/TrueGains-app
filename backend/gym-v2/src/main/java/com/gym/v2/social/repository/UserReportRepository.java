package com.gym.v2.social.repository;

import com.gym.v2.social.entity.ReportStatus;
import com.gym.v2.social.entity.UserReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserReportRepository extends JpaRepository<UserReport, Long> {

	boolean existsByReporterIdAndReportedUserIdAndStatus(Long reporterId, Long reportedUserId, ReportStatus status);

	@Query("SELECT COUNT(r) FROM UserReport r WHERE r.reportedUserId = :userId AND r.status = :status")
	long countByReportedUser(@Param("userId") Long userId, @Param("status") ReportStatus status);

}
