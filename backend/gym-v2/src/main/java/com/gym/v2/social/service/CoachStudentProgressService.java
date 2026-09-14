package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.AppUserRepository;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.SecurityUtils;
import com.gym.v2.core.util.FileUrls;
import com.gym.v2.social.dto.CoachStudentProgressDto;
import com.gym.v2.social.dto.CreateProgressRequest;
import com.gym.v2.social.entity.CoachStudentProgress;
import com.gym.v2.social.repository.CoachStudentProgressRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CoachStudentProgressService {

	private final CoachStudentProgressRepository progressRepository;

	private final CoachRepository coachRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository userRepository;

	private final SocialMapper socialMapper;

	public CoachStudentProgressService(CoachStudentProgressRepository progressRepository,
			CoachRepository coachRepository, ClientRepository clientRepository, AppUserRepository userRepository,
			SocialMapper socialMapper) {
		this.progressRepository = progressRepository;
		this.coachRepository = coachRepository;
		this.clientRepository = clientRepository;
		this.userRepository = userRepository;
		this.socialMapper = socialMapper;
	}

	@Transactional
	public CoachStudentProgressDto createProgressRequest(CreateProgressRequest request) {
		AppUser currentUser = getCurrentUser();
		CoachEntity coach = coachRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Sadece antrenörler gelişim talebi oluşturabilir."));

		ClientEntity client = clientRepository.findByUserId(request.clientId())
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı."));

		// Güvenlik: Sporcu koçun öğrencisi mi?
		if (client.getCoachId() == null || !client.getCoachId().equals(coach.getUserId())) {
			throw new BadRequestException("Sadece kendi öğrencileriniz için gelişim talebi oluşturabilirsiniz.");
		}

		CoachStudentProgress progress = new CoachStudentProgress();
		progress.setCoach(coach);
		progress.setClient(client);
		progress.setStudentNickname(request.studentNickname());
		// Sunucu adı saklanmaz; gerekçe FileUrls'te. Görseli açan sporcunun IP'si yabancı
		// bir sunucuya gitmemeli.
		progress.setBeforeImageUrl(FileUrls.toStoredPath(request.beforeImageUrl()));
		progress.setAfterImageUrl(FileUrls.toStoredPath(request.afterImageUrl()));
		progress.setDescription(request.description());
		progress.setStatus("PENDING");

		CoachStudentProgress saved = progressRepository.save(progress);
		return socialMapper.toProgressDto(saved);
	}

	@Transactional(readOnly = true)
	public List<CoachStudentProgressDto> getPendingRequestsForClient() {
		AppUser currentUser = getCurrentUser();
		return socialMapper
			.toProgressDtoList(progressRepository.findByClientUserIdAndStatus(currentUser.getId(), "PENDING"));
	}

	@Transactional
	public CoachStudentProgressDto respondToProgressRequest(Long id, boolean approved) {
		AppUser currentUser = getCurrentUser();
		CoachStudentProgress progress = progressRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Gelişim talebi bulunamadı."));

		if (!progress.getClient().getUserId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu talebe yanıt verme yetkiniz yoktur.");
		}

		progress.setStatus(approved ? "APPROVED" : "REJECTED");
		CoachStudentProgress saved = progressRepository.save(progress);
		return socialMapper.toProgressDto(saved);
	}

	@Transactional(readOnly = true)
	public List<CoachStudentProgressDto> getApprovedProgressForCoach(Long coachId) {
		AppUser currentUser = getCurrentUser();
		if (!currentUser.getId().equals(coachId)) {
			throw new AccessDeniedException("Başka bir antrenörün verilerine erişemezsiniz.");
		}
		return socialMapper.toProgressDtoList(progressRepository.findByCoachUserIdAndStatus(coachId, "APPROVED"));
	}

	@Transactional
	public void deleteProgress(Long id) {
		AppUser currentUser = getCurrentUser();
		CoachStudentProgress progress = progressRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Gelişim kaydı bulunamadı."));

		boolean isCoach = progress.getCoach().getUserId().equals(currentUser.getId());
		boolean isClient = progress.getClient().getUserId().equals(currentUser.getId());

		if (!isCoach && !isClient) {
			throw new BadRequestException("Bu kaydı silme yetkiniz yoktur.");
		}

		progressRepository.delete(progress);
	}

	private AppUser getCurrentUser() {
		String email = SecurityUtils.getCurrentUserEmail();
		return userRepository.findByEmail(email).orElseThrow(() -> new NotFoundException("Kullanıcı bulunamadı."));
	}

}
