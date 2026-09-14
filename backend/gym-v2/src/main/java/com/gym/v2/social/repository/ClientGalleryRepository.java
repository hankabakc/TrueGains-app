package com.gym.v2.social.repository;

import com.gym.v2.social.entity.ClientGallery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClientGalleryRepository extends JpaRepository<ClientGallery, Long> {

	List<ClientGallery> findByClientUserIdOrderByCreatedAtDesc(Long clientId);

}
