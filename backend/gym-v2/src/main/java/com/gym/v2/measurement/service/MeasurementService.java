package com.gym.v2.measurement.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.measurement.dto.ClientMeasurementsSummaryRecord;
import com.gym.v2.measurement.dto.MeasurementDTO;
import com.gym.v2.measurement.dto.SharedMeasurementRecord;
import com.gym.v2.measurement.entity.Measurement;
import com.gym.v2.measurement.repository.MeasurementRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ölçüm Servisi (MeasurementService)
 */
@Service
public class MeasurementService {

	private final MeasurementRepository measurementRepository;

	private final UserContextService userContextService;

	private final MeasurementMapper measurementMapper;

	private final ClientRepository clientRepository;

	private final EncryptionConverter encryptionConverter;

	private final Clock clock;

	public MeasurementService(final MeasurementRepository measurementRepository,
			final UserContextService userContextService, final MeasurementMapper measurementMapper,
			final ClientRepository clientRepository, final EncryptionConverter encryptionConverter, final Clock clock) {
		this.measurementRepository = measurementRepository;
		this.userContextService = userContextService;
		this.measurementMapper = measurementMapper;
		this.clientRepository = clientRepository;
		this.encryptionConverter = encryptionConverter;
		this.clock = clock;
	}

	@Transactional
	public MeasurementDTO addMeasurement(MeasurementDTO dto) {
		AppUser currentUser = userContextService.getCurrentUser();

		ClientEntity client = clientRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new NotFoundException("Sporcu bilgisi bulunamadı."));

		// MapStruct kullanımı (Anayasa kuralı: Manuel mapping yasak)
		Measurement measurement = measurementMapper.toEntity(dto);
		measurement.setUser(currentUser);

		// Eğer antrenörü yoksa, zorla paylaşımı false yapıyoruz
		if (client.getCoachId() == null) {
			measurement.setIsSharedWithCoach(false);
		}

		Measurement saved = measurementRepository.save(measurement);
		return measurementMapper.toDTO(saved);
	}

	@Transactional(readOnly = true)
	public Page<MeasurementDTO> getMyMeasurements(Pageable pageable) {
		AppUser currentUser = userContextService.getCurrentUser();
		Page<Measurement> measurements = measurementRepository
			.findByUser_ExternalIdOrderByCreatedAtDesc(currentUser.getExternalId(), pageable);
		return measurements.map(measurementMapper::toDTO);
	}

	@Transactional(readOnly = true)
	public MeasurementDTO getTodayMeasurement() {
		AppUser currentUser = userContextService.getCurrentUser();

		Instant startOfToday = clock.instant().truncatedTo(ChronoUnit.DAYS);
		Instant endOfToday = startOfToday.plus(1, ChronoUnit.DAYS);

		return measurementRepository
			.findFirstByUser_ExternalIdAndCreatedAtBetween(currentUser.getExternalId(), startOfToday, endOfToday)
			.map(measurementMapper::toDTO)
			.orElse(null);
	}

	@Transactional
	public void deleteMeasurement(Long id) {
		Measurement measurement = measurementRepository.findById(id)
			.orElseThrow(() -> new NotFoundException("Ölçüm kaydı bulunamadı."));

		AppUser currentUser = userContextService.getCurrentUser();

		// Yetki Kontrolü: 400 BadRequest değil, 403 Forbidden (AccessDeniedException)
		// olmalı
		if (!Objects.equals(measurement.getUser().getId(), currentUser.getId())) {
			throw new AccessDeniedException("Bu ölçümü silme yetkiniz yoktur.");
		}
		measurementRepository.delete(measurement);
	}

	@Transactional(readOnly = true)
	public Page<MeasurementDTO> getClientMeasurements(Long clientId, Pageable pageable) {
		AppUser currentCoach = userContextService.getCurrentUser();

		// Koç-Sporcu İlişkisi Kontrolü
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu kaydı bulunamadı."));

		if (!Objects.equals(client.getCoachId(), currentCoach.getId())) {
			throw new AccessDeniedException("Bu sporcunun ölçümlerini görme yetkiniz yoktur.");
		}

		Page<Measurement> measurements = measurementRepository
			.findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(clientId, pageable);
		return measurements.map(measurementMapper::toDTO);
	}

	@Transactional
	public void shareMeasurementsWithCoach(List<Long> measurementIds) {
		if (measurementIds == null || measurementIds.isEmpty()) {
			return;
		}

		AppUser currentUser = userContextService.getCurrentUser();

		ClientEntity client = clientRepository.findByUserId(currentUser.getId())
			.orElseThrow(() -> new NotFoundException("Sporcu bilgisi bulunamadı."));

		if (client.getCoachId() == null) {
			throw new BadRequestException("Ölçümleri paylaşabilmek için bir antrenöre bağlı olmanız gerekmektedir.");
		}

		// Giriş listesini mükerrerlikten arındırıyoruz (Güvenlik / Nükleer Zırh)
		List<Long> uniqueIds = measurementIds.stream().distinct().toList();

		// Önce gönderilen ID'lere ait tüm kayıtlar veritabanından çekilecek
		List<Measurement> measurements = measurementRepository.findAllById(uniqueIds);

		// Güvenlik ve veri bütünlüğü kontrolü (Nükleer Zırh)
		if (measurements.size() != uniqueIds.size()) {
			throw new NotFoundException("Seçilen ölçüm kayıtlarından bazıları bulunamadı.");
		}

		for (Measurement measurement : measurements) {
			// Aktif kullanıcıya ait olup olmadığı kontrol edilir
			if (!Objects.equals(measurement.getUser().getId(), currentUser.getId())) {
				throw new AccessDeniedException("Bu ölçüm kayıtlarını paylaşma yetkiniz yoktur.");
			}
			// Zaten paylaşıldıysa hata fırlatılır
			if (Boolean.TRUE.equals(measurement.getIsSharedWithCoach())) {
				throw new BadRequestException("Seçili ölçümlerden bazıları zaten antrenörünüzle paylaşılmış.");
			}
		}

		// Sadece tümü false ise toplu güncelleme yapılacak
		measurementRepository.bulkShareWithCoach(currentUser.getId(), uniqueIds);
	}

	/**
	 * Antrenörün kendisine bağlı sporcular tarafından paylaşılan tüm ölçümleri görmesini
	 * sağlar. Veriler sporcu bazlı gruplandırılır ve isimlerin şifresi çözülür.
	 */
	@Transactional(readOnly = true)
	public List<ClientMeasurementsSummaryRecord> getSharedMeasurementsForCoach() {
		AppUser currentCoach = userContextService.getCurrentUser();
		List<Measurement> sharedMeasurements = measurementRepository.findSharedByCoachId(currentCoach.getId());

		if (sharedMeasurements.isEmpty()) {
			return List.of();
		}

		// Benzersiz sporcu ID'lerini toplayıp tek sorguda bilgileri alıyoruz (N+1 Önleme)
		List<Long> studentIds = sharedMeasurements.stream().map(m -> m.getUser().getId()).distinct().toList();

		List<ClientEntity> clients = clientRepository.findAllByUserIdIn(studentIds);
		java.util.Map<Long, ClientEntity> clientMap = clients.stream()
			.collect(Collectors.toMap(ClientEntity::getUserId, java.util.function.Function.identity()));

		// Sporcu bazlı gruplandırma
		return sharedMeasurements.stream()
			.collect(Collectors.groupingBy(m -> m.getUser().getId()))
			.entrySet()
			.stream()
			.map(entry -> {
				Long studentId = entry.getKey();
				List<Measurement> measurements = entry.getValue();

				ClientEntity client = clientMap.get(studentId);
				if (client == null) {
					throw new NotFoundException("Sporcu bilgisi bulunamadı: ID " + studentId);
				}

				List<SharedMeasurementRecord> sharedRecords = measurements.stream()
					.map(measurementMapper::toSharedRecord)
					.toList();

				return new ClientMeasurementsSummaryRecord(studentId, client.getFullName(), sharedRecords);
			})
			.toList();
	}

	/**
	 * Antrenörün yetkili olduğu tek bir sporcunun paylaştığı ölçümleri getirir.
	 * @param clientId Sporcu ID'si
	 * @return ClientMeasurementsSummaryRecord Sporcunun bilgileri ve paylaştığı ölçümler
	 */
	@Transactional(readOnly = true)
	public ClientMeasurementsSummaryRecord getSharedMeasurementsForClient(Long clientId) {
		AppUser currentCoach = userContextService.getCurrentUser();

		// Koç-Sporcu İlişkisi Kontrolü
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu kaydı bulunamadı."));

		if (!Objects.equals(client.getCoachId(), currentCoach.getId())) {
			throw new AccessDeniedException("Bu sporcunun ölçümlerini görme yetkiniz yoktur.");
		}

		// Sporcunun paylaştığı ölçümler çekilir
		List<Measurement> sharedMeasurements = measurementRepository
			.findByUser_IdAndIsSharedWithCoachTrueOrderByCreatedAtDesc(clientId);

		List<SharedMeasurementRecord> sharedRecords = sharedMeasurements.stream()
			.map(measurementMapper::toSharedRecord)
			.toList();

		return new ClientMeasurementsSummaryRecord(clientId, client.getFullName(), sharedRecords);
	}

}
