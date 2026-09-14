package com.gym.v2.membership.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.*;
import com.gym.v2.auth.repository.RefreshTokenRepository;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.membership.dto.*;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileService {

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	private final AppUserRepository appUserRepository;

	private final PasswordEncoder passwordEncoder;

	private final RefreshTokenRepository refreshTokenRepository;

	private final EncryptionConverter encryptionConverter;

	public ProfileService(ClientRepository clientRepository, CoachRepository coachRepository,
			AppUserRepository appUserRepository, PasswordEncoder passwordEncoder,
			RefreshTokenRepository refreshTokenRepository, EncryptionConverter encryptionConverter) {
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
		this.appUserRepository = appUserRepository;
		this.passwordEncoder = passwordEncoder;
		this.refreshTokenRepository = refreshTokenRepository;
		this.encryptionConverter = encryptionConverter;
	}

	public ClientProfileResponse getMyProfile() {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser user = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		ClientEntity client = clientRepository.findByUserId(user.getId())
			.orElseThrow(() -> new NotFoundException("Profil bulunamadı."));

		return new ClientProfileResponse(client.getUserId(), client.getFullName(), user.getEmail(),
				user.getProfilePhotoUrl(), client.getDateOfBirth(), client.getGender(), client.getHeightCm(),
				client.getWeightKg(), client.getGoal(), client.getActivityLevel(), client.getBio(),
				client.getInstagramUrl(), client.getWebsiteUrl(), client.getTiktokUrl(), client.getPublicPhotos(),
				client.getShowAge(), client.getShowHeight(), client.getShowWeight(), client.getProvince(),
				client.getDistrict(), client.getExperienceLevel());
	}

	public CoachProfileResponse getMyCoachProfile() {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser user = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		CoachEntity coach = coachRepository.findByUserId(user.getId())
			.orElseThrow(() -> new NotFoundException("Antrenör profili bulunamadı."));

		return new CoachProfileResponse(coach.getUserId(), coach.getFullName(), user.getEmail(),
				user.getProfilePhotoUrl(), coach.getBio(), coach.getSpecialization(), coach.getInstagramUrl(),
				coach.getWebsiteUrl(), coach.getTiktokUrl(), coach.getHeightCm(), coach.getWeightKg(),
				coach.getMaxClients());
	}

	@Transactional
	public void updateClientProfile(Long userId, ClientProfileRequest request) {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser currentUser = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Oturum açan kullanıcı bulunamadı."));

		// IDOR Check: Sadece kendi profilini güncelleyebilir
		if (!currentUser.getId().equals(userId)) {
			throw new BadRequestException("Başka bir kullanıcının profilini güncelleyemezsiniz.");
		}

		ClientEntity client = clientRepository.findByUserId(userId)
			.orElseThrow(() -> new NotFoundException("Sporcu profili bulunamadı."));

		currentUser.setProfilePhotoUrl(request.profilePhotoUrl());
		appUserRepository.save(currentUser);

		client.setFullName(request.fullName());
		client.setDateOfBirth(request.dateOfBirth());
		client.setGender(request.gender());
		client.setHeightCm(request.heightCm());
		client.setWeightKg(request.weightKg());
		client.setGoal(request.goal());
		client.setActivityLevel(request.activityLevel());
		client.setBio(request.bio());
		client.setProfilePhotoUrl(request.profilePhotoUrl());
		client.setInstagramUrl(request.instagramUrl());
		client.setWebsiteUrl(request.websiteUrl());
		client.setTiktokUrl(request.tiktokUrl());
		client.setShowAge(request.showAge());
		client.setShowHeight(request.showHeight());
		client.setShowWeight(request.showWeight());

		if (request.province() != null) {
			client.setProvince(request.province());
		}
		if (request.district() != null) {
			client.setDistrict(request.district());
		}
		if (request.experienceLevel() != null) {
			client.setExperienceLevel(request.experienceLevel());
		}

		if (request.publicPhotos() != null) {
			client.getPublicPhotos().clear();
			client.getPublicPhotos().addAll(request.publicPhotos());
		}

		clientRepository.save(client);
	}

	@Transactional
	public void changePassword(ChangePasswordRequest request) {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser user = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		if (!passwordEncoder.matches(request.currentPassword(), user.getPassword())) {
			throw new BadRequestException("Mevcut şifre hatalı.");
		}

		user.setPassword(passwordEncoder.encode(request.newPassword()));
		appUserRepository.save(user);

		// Şifre değiştiren kullanıcı çoğu zaman hesabının ele geçirildiğinden şüphelenir.
		// Yenileme token'ları silinmezse saldırganın oturumu yenilenmeye devam eder ve
		// şifre değiştirmek onu dışarı atmaz. AuthenticationService.resetPassword da aynı
		// şeyi yapıyor.
		refreshTokenRepository.deleteAllByUser(user);
	}

	@Transactional
	public void updateCoachProfile(Long userId, CoachProfileRequest request) {
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser currentUser = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Oturum açan kullanıcı bulunamadı."));

		if (!currentUser.getId().equals(userId)) {
			throw new BadRequestException("Başka bir kullanıcının profilini güncelleyemezsiniz.");
		}

		CoachEntity coach = coachRepository.findByUserId(userId)
			.orElseThrow(() -> new NotFoundException("Antrenör profili bulunamadı."));

		currentUser.setProfilePhotoUrl(request.getProfilePhotoUrl());
		appUserRepository.save(currentUser);

		coach.setFullName(request.getFullName());
		coach.setBio(request.bio());
		coach.setSpecialization(request.specialization());
		coach.setProfilePhotoUrl(request.getProfilePhotoUrl());
		coach.setInstagramUrl(request.instagramUrl());
		if (request.websiteUrl() != null) {
			coach.setWebsiteUrl(request.websiteUrl());
		}
		coach.setTiktokUrl(request.tiktokUrl());
		coach.setHeightCm(request.heightCm());
		coach.setWeightKg(request.weightKg());
		coach.setExperienceYears(request.experienceYears());
		coach.setProvince(request.province());
		coach.setDistrict(request.district());

		coachRepository.save(coach);
	}

	/**
	 * Antrenörün yetkili olduğu sporcunun (öğrencinin) profil bilgilerini getirir. PII
	 * kapsamında şifreli isim ve bio alanları çözülerek plain text olarak döndürülür.
	 * @param clientId Bilgileri istenecek sporcunun benzersiz ID'si
	 * @return ClientProfileResponse Sporcu profil bilgileri
	 */
	@Transactional(readOnly = true)
	public ClientProfileResponse getClientProfileForCoach(Long clientId) {
		// İşlemi yapan güncel koç kullanıcısı alınır.
		String email = SecurityUtils.getCurrentUserEmail();
		AppUser coachUser = appUserRepository.findByEmail(email)
			.orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));

		// Bilgileri istenen sporcunun profil verisi sorgulanır.
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu profili bulunamadı. ID: " + clientId));

		// Sporcu kimliği URL'den geldiği için COACH rolüne sahip olmak yetmez: yanıt
		// e-posta, doğum tarihi ve vücut ölçüleri gibi şifresi çözülmüş kişisel veri
		// içerir; yalnızca sporcunun kendi antrenörü görebilir.
		if (client.getCoachId() == null || !client.getCoachId().equals(coachUser.getId())) {
			throw new AccessDeniedException("Bu sporcunun profiline erişim yetkiniz yoktur.");
		}

		// Şifreli veri alanları çözülerek (decrypted) DTO yapısıyla geri döndürülür.
		return new ClientProfileResponse(client.getUserId(), client.getFullName(), client.getUser().getEmail(),
				client.getUser().getProfilePhotoUrl(), client.getDateOfBirth(), client.getGender(),
				client.getHeightCm(), client.getWeightKg(), client.getGoal(), client.getActivityLevel(),
				client.getBio(), client.getInstagramUrl(), client.getWebsiteUrl(), client.getTiktokUrl(),
				client.getPublicPhotos(), client.getShowAge(), client.getShowHeight(), client.getShowWeight(),
				client.getProvince(), client.getDistrict(), client.getExperienceLevel());
	}

}
