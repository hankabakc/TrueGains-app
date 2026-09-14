package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.*;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.social.dto.*;
import com.gym.v2.social.entity.*;
import com.gym.v2.social.repository.PairingRequestRepository;
import com.gym.v2.social.repository.ConversationRepository;
import com.gym.v2.core.security.EncryptionConverter;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.PageImpl;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.List;
import java.util.Objects;

/**
 * GYMAPP-V2 Sosyal Modül: Antrenör ve Danışan Eşleşme Servisi.
 */
@Service
public class PairingService {

	private final PairingRequestRepository pairingRequestRepository;

	private final ConversationRepository conversationRepository;

	private final CoachRepository coachRepository;

	private final ClientRepository clientRepository;

	private final AppUserRepository appUserRepository;

	private final UserContextService userContextService;

	private final SocialMapper socialMapper;

	private final Clock clock;

	private final EncryptionConverter encryptionConverter;

	public PairingService(PairingRequestRepository pairingRequestRepository,
			ConversationRepository conversationRepository, CoachRepository coachRepository,
			ClientRepository clientRepository, AppUserRepository appUserRepository,
			UserContextService userContextService, SocialMapper socialMapper, Clock clock,
			EncryptionConverter encryptionConverter) {
		this.pairingRequestRepository = pairingRequestRepository;
		this.conversationRepository = conversationRepository;
		this.coachRepository = coachRepository;
		this.clientRepository = clientRepository;
		this.appUserRepository = appUserRepository;
		this.userContextService = userContextService;
		this.socialMapper = socialMapper;
		this.clock = clock;
		this.encryptionConverter = encryptionConverter;
	}

	@Transactional(readOnly = true)
	public Page<CoachDiscoveryDTO> discoverCoaches(String specialization, String name, Double minRating, String sort,
			Pageable pageable) {
		// Sıralama sorgunun İÇİNDE (bkz. CoachRepository.searchCoaches). Buradan
		// sıralı bir Pageable geçilirse Hibernate ikinci bir ORDER BY ekler ve sorgu
		// bozulur; o yüzden Pageable bilerek sıralamasız gönderiliyor.
		String normalizedSort = "newest".equals(sort) ? "newest" : "rating";

		String normalizedSpec = (specialization == null || specialization.isBlank()) ? null : specialization;

		if (name == null || name.isBlank()) {
			Pageable effective = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize());
			return coachRepository.searchCoaches(normalizedSpec, minRating, normalizedSort, effective)
				.map(this::mapProjectionToDiscoveryDTO);
		}
		else {
			// ponytail: isim araması bellekte (AES isimler DB'de LIKE'lanamıyor); ~10k
			// koç üstünde blind-index/HMAC'e geç
			List<com.gym.v2.social.dto.CoachDiscoveryProjection> all = coachRepository
				.searchCoaches(normalizedSpec, minRating, normalizedSort, Pageable.unpaged())
				.getContent();

			String q = name.trim().toLowerCase(java.util.Locale.forLanguageTag("tr"));

			List<com.gym.v2.social.dto.CoachDiscoveryProjection> matched = all.stream()
				.filter(p -> encryptionConverter.convertToEntityAttribute(p.getFullName())
					.toLowerCase(java.util.Locale.forLanguageTag("tr"))
					.contains(q))
				.toList();

			int size = pageable.getPageSize();
			int from = pageable.getPageNumber() * size;
			int to = Math.min(from + size, matched.size());

			List<com.gym.v2.social.dto.CoachDiscoveryProjection> pageRows = (from >= matched.size())
					? java.util.List.of() : matched.subList(from, to);

			List<CoachDiscoveryDTO> dtos = pageRows.stream().map(this::mapProjectionToDiscoveryDTO).toList();

			return new PageImpl<>(dtos, PageRequest.of(pageable.getPageNumber(), size), matched.size());
		}
	}

	/**
	 * Keşfet listesi. Yalnızca <b>antrenör</b> listelenebilir.
	 * <p>
	 * Sporcu listeleme yolu kaldırıldı. Kimlik doğrulaması olan herkes
	 * {@code role=CLIENT} göndererek sistemdeki bütün sporcuların ad-soyadını,
	 * biyografisini ve fotoğrafını sayfalayabiliyordu; bunlardan ikisi veritabanında AES
	 * ile şifrelenmiş kişisel veri, varlık getter'ı ise yanıta çözülmüş hâlini koyuyor.
	 * Şifreleme, veriyi API'den akıtan bir uçta işe yaramaz.
	 * </p>
	 * <p>
	 * Kaldırmanın işlevsel bedeli yok: liste her sporcu için
	 * {@code canSendRequest = false} döndürüyordu, yani üzerinde yapılabilecek bir işlem
	 * yoktu. Koç→sporcu yönünde bir keşif özelliği istenirse, rıza ve yetkilendirme
	 * modeliyle birlikte tasarlanmalıdır.
	 * </p>
	 */
	@Transactional(readOnly = true)
	public Page<DiscoveryUserDto> discoverUsers(UserRole role, Pageable pageable) {
		AppUser currentUser = userContextService.getCurrentUser();
		boolean isCurrentCoach = currentUser.getRole() == UserRole.COACH;

		if (role == UserRole.COACH) {
			return coachRepository.findAll(pageable).map(coach -> mapToDiscoveryUserDto(coach, isCurrentCoach));
		}

		if (role == UserRole.CLIENT) {
			// Sporcu listesini yalnızca koçlar görebilir. Sporcular birbirini
			// listeleyemez: aksi hâlde her kullanıcı tüm sporcuların adını,
			// biyografisini ve fotoğrafını sayfalayarak toplayabilirdi.
			if (!isCurrentCoach) {
				throw new AccessDeniedException("Sporcu listesini yalnızca antrenörler görüntüleyebilir.");
			}
			return clientRepository.findAll(pageable).map(client -> mapToDiscoveryUserDto(client, isCurrentCoach));
		}

		throw new BadRequestException("Bu listede yalnızca antrenörler veya sporcular görüntülenebilir.");
	}

	private DiscoveryUserDto mapToDiscoveryUserDto(CoachEntity coach, boolean isCurrentCoach) {
		// Koçlar diğer koçlara istek atamaz. Sadece sporcular (client) koçlara istek
		// atabilir.
		boolean canSendRequest = !isCurrentCoach;

		return new DiscoveryUserDto(coach.getUserId(), coach.getFullName(), coach.getBio(), coach.getProfilePhotoUrl(),
				UserRole.COACH, coach.getSpecialization(), coach.getCurrency(), canSendRequest);
	}

	private DiscoveryUserDto mapToDiscoveryUserDto(ClientEntity client, boolean isCurrentCoach) {
		// Sporcular arası eşleşme isteği şu anki mimaride desteklenmiyor.
		// Koçlar da sporculara direkt istek atamaz (sporcular koçlara atar).
		return new DiscoveryUserDto(client.getUserId(), client.getFullName(), client.getBio(),
				client.getProfilePhotoUrl(), UserRole.CLIENT, null, null, false);
	}

	@Transactional
	public PairingRequestDTO sendPairingRequest(CreatePairingRequest request) {
		AppUser currentUser = userContextService.getCurrentUser();

		ClientEntity client = clientRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new BadRequestException("Sadece sporcular eşleşme isteği gönderebilir."));

		CoachEntity coach = coachRepository.findByUserId(request.coachId())
			.orElseThrow(() -> new NotFoundException("Antrenör bulunamadı."));

		pairingRequestRepository
			.findByClient_UserIdAndCoach_UserIdAndStatus(client.getUserId(), coach.getUserId(), PairingStatus.PENDING)
			.ifPresent(req -> {
				throw new BadRequestException("Bu antrenöre zaten bekleyen bir isteğiniz bulunuyor.");
			});

		PairingRequest pairingRequest = new PairingRequest();
		pairingRequest.setClient(client);
		pairingRequest.setCoach(coach);
		pairingRequest.setMessage(request.message());
		pairingRequest.setStatus(PairingStatus.PENDING);

		pairingRequest.onPersist(clock.instant());

		PairingRequest saved = pairingRequestRepository.save(pairingRequest);
		return socialMapper.toPairingDTO(saved);
	}

	@Transactional(readOnly = true)
	public List<PairingRequestDTO> getPendingRequestsForCoach() {
		AppUser currentUser = userContextService.getCurrentUser();
		List<PairingRequest> requests = pairingRequestRepository.findByCoach_UserIdAndStatus(currentUser.getId(),
				PairingStatus.PENDING);
		return socialMapper.toPairingDTOList(requests);
	}

	@Transactional
	public void respondToRequest(Long requestId, boolean accepted) {
		AppUser currentUser = userContextService.getCurrentUser();
		PairingRequest request = pairingRequestRepository.findById(requestId)
			.orElseThrow(() -> new NotFoundException("İstek bulunamadı."));

		if (!Objects.equals(request.getCoach().getUserId(), currentUser.getId())) {
			throw new AccessDeniedException("Bu işlemi yapmaya yetkiniz yok.");
		}

		if (accepted) {
			request.setStatus(PairingStatus.ACCEPTED);

			// Race condition (Eşzamanlı limit aşımı) engellemek için koç kaydını
			// kilitliyoruz (Pessimistic Lock)
			CoachEntity coach = coachRepository.findByUserIdWithLock(request.getCoach().getUserId())
				.orElseThrow(() -> new NotFoundException("Antrenör bilgisi kilitlenirken bulunamadı."));

			int currentActiveClients = clientRepository.countByCoachId(coach.getUserId());

			if (currentActiveClients >= coach.getMaxClients()) {
				throw new BadRequestException("Maksimum öğrenci kapasitenize ulaştınız.");
			}

			ClientEntity client = request.getClient();

			// Sporcunun ZATEN bir koçu varsa istek kabul edilemez.
			// PENDING istekler hiç sona ermiyor; bu kontrol olmadan koç aylar önceki bir
			// isteği açıp kabul ettiğinde, o arada başka bir koçla eşleşip paket satın
			// almış
			// sporcu sessizce yeni koça geçiyordu: eski koçun programları öksüz kalıyor,
			// abonelik eski koçta kalmaya devam ediyor ve sporcu hiçbir onay vermiyordu.
			if (client.getCoachId() != null && !client.getCoachId().equals(coach.getUserId())) {
				throw new BadRequestException("Bu sporcunun hâlihazırda bir antrenörü var. "
						+ "Yeni bir eşleşme için sporcunun önce mevcut antrenöründen ayrılması gerekir.");
			}

			client.setCoachId(coach.getUserId());
			clientRepository.save(client);
			createConversationIfNotExist(client.getUserId(), coach.getUserId());
		}
		else {
			request.setStatus(PairingStatus.REJECTED);
		}

		request.onUpdate(clock.instant());

		pairingRequestRepository.save(request);
	}

	private void createConversationIfNotExist(Long clientId, Long coachId) {
		if (conversationRepository.findByClientIdAndCoachId(clientId, coachId).isEmpty()) {
			Conversation conv = new Conversation();
			conv.setClient(appUserRepository.getReferenceById(clientId));
			conv.setCoach(appUserRepository.getReferenceById(coachId));
			conv.onPersist(clock.instant());
			conversationRepository.save(conv);
		}
	}

	private CoachDiscoveryDTO mapProjectionToDiscoveryDTO(com.gym.v2.social.dto.CoachDiscoveryProjection p) {
		return new CoachDiscoveryDTO(p.getUserId(), encryptionConverter.convertToEntityAttribute(p.getFullName()),
				encryptionConverter.convertToEntityAttribute(p.getBio()), p.getSpecialization(), p.getCurrency(),
				p.getProfilePhotoUrl(), p.getInstagramUrl(), p.getAverageRating(), p.getReviewCount(),
				p.getActiveStudentCount(), p.getProvince(), p.getDistrict(), p.getExperienceYears(),
				p.getMinPackagePrice());
	}

	/**
	 * Antrenörün aktif öğrencilerini listeler.
	 */
	@Transactional(readOnly = true)
	public List<DiscoveryUserDto> getMyActiveClients() {
		AppUser currentUser = userContextService.getCurrentUser();
		if (currentUser.getRole() != UserRole.COACH) {
			throw new BadRequestException("Bu işlemi sadece antrenörler yapabilir.");
		}

		List<ClientEntity> clients = clientRepository.findAllByCoachId(currentUser.getId());

		return clients.stream()
			.map(c -> new DiscoveryUserDto(c.getUserId(), c.getFullName(), c.getBio(), c.getProfilePhotoUrl(),
					UserRole.CLIENT, null, // Specialization
					null, // Currency null
					false // canSendRequest
			))
			.toList();
	}

}
