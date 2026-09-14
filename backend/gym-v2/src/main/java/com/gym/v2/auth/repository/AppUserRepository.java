package com.gym.v2.auth.repository;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.Optional;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

	Optional<AppUser> findByEmail(String email);

	@Query("SELECT u.id FROM AppUser u WHERE u.email = :email")
	Optional<Long> findIdByEmail(String email);

	boolean existsByEmail(String email);

	/** İlk yönetici hesabının yalnızca bir kez açılması için (bkz. AdminBootstrap). */
	boolean existsByRole(UserRole role);

}
