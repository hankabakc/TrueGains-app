package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.finance.repository.ClientSubscriptionRepository;
import com.gym.v2.social.dto.*;
import com.gym.v2.social.entity.CoachGallery;
import com.gym.v2.social.entity.CoachReview;
import com.gym.v2.social.repository.CoachGalleryRepository;
import com.gym.v2.social.repository.CoachReviewRepository;
import com.gym.v2.social.repository.CoachStudentProgressRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.List;

/**
 * Antrenör profil ve sosyal etkileşim (Yorum, Galeri) servisi. Bulgu #2: Zaman yönetimi
 * Clock bean üzerinden sağlanmaktadır.
 */
@Service
public class CoachProfileService {

	private final CoachRepository coachRepository;

	private final CoachGalleryRepository galleryRepository;

	private final CoachReviewRepository reviewRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository userRepository;

	private final SocialMapper socialMapper;

	private final ClientSubscriptionRepository subscriptionRepository;

	private final CoachStudentProgressRepository progressRepository;

	private final Clock clock;

	private final EncryptionConverter encryptionConverter;

	public CoachProfileService(CoachRepository coachRepository, CoachGalleryRepository galleryRepository,
			CoachReviewRepository reviewRepository, ClientRepository clientRepository, AppUserRepository userRepository,
			SocialMapper socialMapper, ClientSubscriptionRepository subscriptionRepository,
			CoachStudentProgressRepository progressRepository, Clock clock, EncryptionConverter encryptionConverter) {
		this.coachRepository = coachRepository;
		this.galleryRepository = galleryRepository;
		this.reviewRepository = reviewRepository;
		this.clientRepository = clientRepository;
		this.userRepository = userRepository;
		this.socialMapper = socialMapper;
		this.subscriptionRepository = subscriptionRepository;
		this.progressRepository = progressRepository;
		this.clock = clock;
		this.encryptionConverter = encryptionConverter;
	}

	@Transactional(readOnly = true)
	public CoachProfileResponse getCoachProfile(Long coachId) {
		CoachEntity coach = coachRepository.findByUserId(coachId)
			.orElseThrow(() -> new NotFoundException("Antrenör bulunamadı."));

		List<CoachGallery> portfolio = galleryRepository.findByCoachUserIdAndIsStudentProgress(coachId, false);
		List<CoachGallery> studentProgress = galleryRepository.findByCoachUserIdAndIsStudentProgress(coachId, true);

		List<CoachGalleryDto> portfolioDto = socialMapper.toGalleryDtoList(portfolio);
		List<CoachGalleryDto> progressDto = socialMapper.toGalleryDtoList(studentProgress);

		boolean isSubscribed = checkSubscription(coachId);

		List<CoachStudentProgressDto> authorizedProgress = socialMapper
			.toProgressDtoList(progressRepository.findByCoachUserIdAndStatus(coachId, "APPROVED"));

		Double averageRating = reviewRepository.getAverageRatingByCoachUserId(coachId);
		int reviewCount = reviewRepository.countByCoachUserId(coachId);
		int activeStudentCount = clientRepository.countByCoachId(coachId);
		java.time.Instant memberSince = userRepository.findById(coachId)
			.map(com.gym.v2.auth.entity.AppUser::getRegisteredAt)
			.orElse(null);

		return new CoachProfileResponse(coach.getUserId(), coach.getFullName(), coach.getProfilePhotoUrl(),
				coach.getBio(), coach.getSpecialization(), coach.getCurrency(), "0-50", isSubscribed,
				coach.getInstagramUrl(), coach.getTiktokUrl(), coach.getHeightCm(), coach.getWeightKg(), portfolioDto,
				progressDto, authorizedProgress, averageRating, reviewCount, activeStudentCount, memberSince,
				coach.getExperienceYears(), coach.getProvince(), coach.getDistrict());
	}

	@Transactional(readOnly = true)
	public Page<CoachReviewDto> getReviews(Long coachId, Pageable pageable) {
		return reviewRepository.findByCoachUserId(coachId, pageable).map(socialMapper::toReviewDto);
	}

	@Transactional
	public CoachReviewDto addReview(Long coachId, Integer rating, String comment) {
		AppUser currentUser = getCurrentUser();
		ClientEntity client = clientRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Sadece sporcular değerlendirme yapabilir."));

		CoachEntity coach = coachRepository.findByUserId(coachId)
			.orElseThrow(() -> new NotFoundException("Antrenör bulunamadı."));

		// Abonelik doğrulaması (Adım 4) ve yakalanması
		com.gym.v2.finance.entity.ClientSubscription activeSub = subscriptionRepository
			.findActiveSubscriptionByClientId(client.getUserId())
			.filter(sub -> sub.getCoach() != null && sub.getCoach().getId().equals(coachId))
			.orElseThrow(() -> new BadRequestException(
					"Bu antrenörü değerlendirmek için aktif bir aboneliğiniz olmalıdır."));

		// Bulgu #5: Mükerrer değerlendirme kontrolü
		reviewRepository.findByCoachUserIdAndClientUserId(coachId, client.getUserId()).ifPresent(r -> {
			throw new BadRequestException("Bu antrenörü zaten değerlendirdiniz.");
		});

		CoachReview review = new CoachReview();
		review.setCoach(coach);
		review.setClient(client);
		review.setRating(rating);
		String sanitizedComment = comment != null ? org.springframework.web.util.HtmlUtils.htmlEscape(comment.trim())
				: null;
		review.setComment(sanitizedComment);
		review.setPackageName(activeSub.getPkg().getName());

		// Bulgu #2: onPersist kullanımı
		review.onPersist(clock.instant());

		CoachReview saved = reviewRepository.save(review);
		return socialMapper.toReviewDto(saved);
	}

	@Transactional
	public CoachGalleryDto addGalleryItem(AddGalleryItemRequest request) {
		AppUser currentUser = getCurrentUser();
		CoachEntity coach = coachRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Sadece antrenörler galeriye resim ekleyebilir."));

		CoachGallery item = new CoachGallery();
		item.setCoach(coach);
		item.setImageUrl(request.imageUrl());
		item.setIsStudentProgress(request.isStudentProgress() != null && request.isStudentProgress());
		item.onPersist(clock.instant());

		CoachGallery saved = galleryRepository.save(item);
		return socialMapper.toGalleryDto(saved);
	}

	@Transactional
	public void deleteGalleryItem(Long galleryItemId) {
		AppUser currentUser = getCurrentUser();
		CoachGallery item = galleryRepository.findById(galleryItemId)
			.orElseThrow(() -> new NotFoundException("Galeri öğesi bulunamadı."));

		if (!item.getCoach().getUserId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu galeri öğesini silme yetkiniz yoktur.");
		}

		galleryRepository.delete(item);
	}

	private boolean checkSubscription(Long coachId) {
		String email = SecurityUtils.getCurrentUserEmail();
		if (email == null) {
			return false;
		}
		return userRepository.findByEmail(email)
			.flatMap(user -> subscriptionRepository.findActiveSubscriptionByClientId(user.getId()))
			.map(sub -> sub.getCoach() != null && sub.getCoach().getId().equals(coachId))
			.orElse(false);
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
