package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.social.dto.ClientGalleryDto;
import com.gym.v2.social.entity.ClientGallery;
import com.gym.v2.social.repository.ClientGalleryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ClientGalleryService {

	private final ClientGalleryRepository galleryRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository userRepository;

	private final SocialMapper socialMapper;

	public ClientGalleryService(ClientGalleryRepository galleryRepository, ClientRepository clientRepository,
			AppUserRepository userRepository, SocialMapper socialMapper) {
		this.galleryRepository = galleryRepository;
		this.clientRepository = clientRepository;
		this.userRepository = userRepository;
		this.socialMapper = socialMapper;
	}

	@Transactional(readOnly = true)
	public List<ClientGalleryDto> getMyGallery() {
		AppUser currentUser = getCurrentUser();
		return socialMapper
			.toClientGalleryDtoList(galleryRepository.findByClientUserIdOrderByCreatedAtDesc(currentUser.getId()));
	}

	@Transactional
	public ClientGalleryDto addToGallery(String imageUrl) {
		AppUser currentUser = getCurrentUser();
		ClientEntity client = clientRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Sadece sporcular galeriye resim ekleyebilir."));

		ClientGallery gallery = new ClientGallery();
		gallery.setClient(client);
		gallery.setImageUrl(imageUrl);

		ClientGallery saved = galleryRepository.save(gallery);
		return socialMapper.toClientGalleryDto(saved);
	}

	@Transactional
	public void deleteGalleryItem(Long id) {
		AppUser currentUser = getCurrentUser();
		ClientGallery item = galleryRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Galeri öğesi bulunamadı."));

		if (!item.getClient().getUserId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu galeri öğesini silme yetkiniz yoktur.");
		}

		galleryRepository.delete(item);
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
