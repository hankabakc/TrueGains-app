package com.gym.v2.social.repository;

import com.gym.v2.social.entity.CoachGallery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CoachGalleryRepository extends JpaRepository<CoachGallery, Long> {

	List<CoachGallery> findByCoachUserId(Long coachId);

	List<CoachGallery> findByCoachUserIdAndIsStudentProgress(Long coachId, Boolean isStudentProgress);

}
