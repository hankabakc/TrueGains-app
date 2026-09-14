package com.gym.v2.social.service;

import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.entity.CoachEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.social.entity.PairingRequest;
import com.gym.v2.social.entity.PairingStatus;
import com.gym.v2.social.repository.PairingRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.Objects;

/**
 * Sporcuların antrenörlere koçluk isteği göndermesini yöneten servis sınıfı.
 */
// @Service
public class CoachRequestService {

	private static final Logger log = LoggerFactory.getLogger(CoachRequestService.class);

	private final PairingRequestRepository pairingRequestRepository;

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	private final Clock clock;

	/**
	 * Constructor-based dependency injection.
	 */
	public CoachRequestService(PairingRequestRepository pairingRequestRepository, ClientRepository clientRepository,
			CoachRepository coachRepository, Clock clock) {
		this.pairingRequestRepository = pairingRequestRepository;
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
		this.clock = clock;
	}

	/**
	 * Sporcudan antrenöre koçluk isteği gönderir.
	 * @param clientId İsteği gönderen sporcunun ID'si
	 * @param coachId Hedef antrenörün ID'si
	 */
	@Transactional
	public void sendRequestToCoach(Long clientId, Long coachId) {
		log.info("[COACH_REQUEST] Yeni koçluk isteği gönderiliyor. Client: {}, Coach: {}", clientId, coachId);

		// 1. Validasyonlar
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new BadRequestException("Sadece sporcular koçluk isteği gönderebilir."));

		CoachEntity coach = coachRepository.findByUserId(coachId)
			.orElseThrow(() -> new NotFoundException("Hedef antrenör bulunamadı."));

		// Mükerrer istek kontrolü (PENDING)
		boolean hasPendingRequest = pairingRequestRepository.existsByClient_UserIdAndCoach_UserIdAndStatus(clientId,
				coachId, PairingStatus.PENDING);
		if (hasPendingRequest) {
			throw new BadRequestException("Bu antrenöre zaten beklemede olan bir isteğiniz bulunuyor.");
		}

		// Zaten bağlı mı kontrolü
		if (Objects.equals(client.getCoachId(), coachId)) {
			throw new BadRequestException("Bu antrenör ile zaten çalışıyorsunuz.");
		}

		// 2. İstek oluşturma
		PairingRequest request = new PairingRequest();
		request.setClient(client);
		request.setCoach(coach);
		request.setStatus(PairingStatus.PENDING);
		request.onPersist(clock.instant());

		pairingRequestRepository.save(request);
		log.info("[COACH_REQUEST] Koçluk isteği başarıyla oluşturuldu.");
	}

}
