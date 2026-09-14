package com.gym.v2.social.repository;

import com.gym.v2.social.entity.PairingRequest;
import com.gym.v2.social.entity.PairingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PairingRequestRepository extends JpaRepository<PairingRequest, Long> {

	@Query("SELECT pr FROM PairingRequest pr JOIN FETCH pr.client JOIN FETCH pr.coach WHERE pr.coach.userId = :coachId AND pr.status = :status")
	List<PairingRequest> findByCoach_UserIdAndStatus(Long coachId, PairingStatus status);

	List<PairingRequest> findByClient_UserId(Long clientId);

	Optional<PairingRequest> findByClient_UserIdAndCoach_UserIdAndStatus(Long clientId, Long coachId,
			PairingStatus status);

	boolean existsByClient_UserIdAndCoach_UserIdAndStatus(Long clientId, Long coachId, PairingStatus status);

	Optional<PairingRequest> findByClient_UserIdAndCoach_UserId(Long clientId, Long coachId);

}
