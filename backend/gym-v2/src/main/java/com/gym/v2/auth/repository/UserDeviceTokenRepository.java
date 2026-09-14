package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.UserDeviceToken;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserDeviceTokenRepository extends JpaRepository<UserDeviceToken, Long> {

	List<UserDeviceToken> findAllByUserId(Long userId);

	Optional<UserDeviceToken> findByToken(String token);

	void deleteByToken(String token);

	void deleteAllByUserId(Long userId);

}
