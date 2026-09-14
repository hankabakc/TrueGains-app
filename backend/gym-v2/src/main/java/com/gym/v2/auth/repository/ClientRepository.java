package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.ClientEntity;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClientRepository extends JpaRepository<ClientEntity, Long> {

	Optional<ClientEntity> findByUserId(Long userId);

	List<ClientEntity> findAllByUserIdIn(List<Long> userIds);

	List<ClientEntity> findAllByCoachId(Long coachId);

	int countByCoachId(Long coachId);

}
