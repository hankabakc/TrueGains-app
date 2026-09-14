package com.gym.v2.social.repository;

import com.gym.v2.social.entity.CoachStudentProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CoachStudentProgressRepository extends JpaRepository<CoachStudentProgress, Long> {

	List<CoachStudentProgress> findByClientUserIdAndStatus(Long clientId, String status);

	List<CoachStudentProgress> findByCoachUserIdAndStatus(Long coachId, String status);

}
