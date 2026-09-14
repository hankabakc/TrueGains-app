package com.gym.v2.social.repository;

import com.gym.v2.social.entity.CoachReview;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import org.springframework.data.repository.query.Param;

@Repository
public interface CoachReviewRepository extends JpaRepository<CoachReview, Long> {

	@org.springframework.data.jpa.repository.Query("SELECT r FROM CoachReview r JOIN FETCH r.client c WHERE r.coach.userId = :coachId")
	Page<CoachReview> findByCoachUserId(@org.springframework.data.repository.query.Param("coachId") Long coachId,
			Pageable pageable);

	Optional<CoachReview> findByCoachUserIdAndClientUserId(Long coachId, Long clientId);

	// Koçun genel yorum puan ortalamasını getirir
	@org.springframework.data.jpa.repository.Query("SELECT AVG(r.rating) FROM CoachReview r WHERE r.coach.userId = :coachId")
	Double getAverageRatingByCoachUserId(@Param("coachId") Long coachId);

	// Koça yapılmış olan toplam yorum sayısını döndürür
	int countByCoachUserId(Long coachId);

}
