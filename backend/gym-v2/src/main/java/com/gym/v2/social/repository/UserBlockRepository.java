package com.gym.v2.social.repository;

import com.gym.v2.social.entity.UserBlock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface UserBlockRepository extends JpaRepository<UserBlock, Long> {

	boolean existsByBlockerIdAndBlockedId(Long blockerId, Long blockedId);

	Optional<UserBlock> findByBlockerIdAndBlockedId(Long blockerId, Long blockedId);

	@Query("SELECT COUNT(b) > 0 FROM UserBlock b WHERE " + "(b.blocker.id = :a AND b.blocked.id = :b) "
			+ "OR (b.blocker.id = :b AND b.blocked.id = :a)")
	boolean existsBlockBetween(@Param("a") Long a, @Param("b") Long b);

}
