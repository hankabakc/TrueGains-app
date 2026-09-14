package com.gym.v2.nutrition.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.ClientEntity;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.core.exception.BadRequestException;
import com.gym.v2.core.exception.NotFoundException;
import com.gym.v2.core.security.EncryptionConverter;
import com.gym.v2.core.security.service.UserContextService;
import com.gym.v2.nutrition.dto.ClientWaterTrackingResponse;
import com.gym.v2.nutrition.repository.WaterIntakeRepository;
import com.gym.v2.nutrition.repository.WaterTargetRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * CoachWaterTrackingService - Antrenörlerin kendilerine bağlı öğrencilerin su
 * tüketimlerini izlemesini sağlar. Pure Java (Lombok yasak) ve Constructor Injection
 * prensiplerine uygun tasarlanmıştır. Detailed-Comment Policy uyarınca tüm adımlar
 * detaylı yorum satırlarıyla açıklanmıştır.
 */
@Service
public class CoachWaterTrackingService {

	private final ClientRepository clientRepository;

	private final WaterIntakeRepository intakeRepository;

	private final WaterTargetRepository targetRepository;

	private final EncryptionConverter encryptionConverter;

	private final UserContextService userContextService;

	private final Clock clock;

	/**
	 * Constructor injection ile gerekli bağımlılıklar enjekte edilir (@Autowired
	 * yasaktır).
	 */
	public CoachWaterTrackingService(ClientRepository clientRepository, WaterIntakeRepository intakeRepository,
			WaterTargetRepository targetRepository, EncryptionConverter encryptionConverter,
			UserContextService userContextService, Clock clock) {
		this.clientRepository = clientRepository;
		this.intakeRepository = intakeRepository;
		this.targetRepository = targetRepository;
		this.encryptionConverter = encryptionConverter;
		this.userContextService = userContextService;
		this.clock = clock;
	}

	/**
	 * Aktif koça bağlı olan tüm öğrencilerin günlük su hedeflerini ve o güne ait toplam
	 * su tüketimlerini getirir.
	 * @return List<ClientWaterTrackingResponse> Öğrencilerin su takip detayları listesi
	 */
	@Transactional(readOnly = true)
	public List<ClientWaterTrackingResponse> getStudentsWaterIntake() {
		// İşlemi yapan güncel koç (kullanıcı) bilgisi alınır.
		AppUser currentUser = userContextService.getCurrentUser();

		// Koçun sorumluluğundaki tüm öğrenciler (ClientEntity) listelenir.
		List<ClientEntity> clients = clientRepository.findAllByCoachId(currentUser.getId());
		List<ClientWaterTrackingResponse> responseList = new ArrayList<>();

		// Sorgunun yapılacağı o günkü tarih saat dilimi sistem saatinden (Clock) alınır.
		LocalDate today = LocalDate.now(clock);

		for (ClientEntity client : clients) {
			// PII gereği veritabanında şifreli (AES-256) tutulan isim deşifre edilmiş
			// olarak gelir.
			String fullName = client.getFullName();
			String firstName = "";
			String lastName = "";

			// Tam isim ad ve soyad olarak ikiye bölünür.
			if (fullName != null && !fullName.isBlank()) {
				String trimmed = fullName.trim();
				int lastSpace = trimmed.lastIndexOf(' ');
				if (lastSpace == -1) {
					firstName = trimmed;
					lastName = "";
				}
				else {
					firstName = trimmed.substring(0, lastSpace);
					lastName = trimmed.substring(lastSpace + 1);
				}
			}

			// Öğrencinin o andaki aktif su hedefi sorgulanır. Hedef yoksa varsayılan 2500
			// ml atanır.
			Integer targetMl = targetRepository.findByUserIdAndValidToIsNull(client.getUserId())
				.map(target -> target.getTargetMl())
				.orElse(2500);

			// Öğrencinin bugün tükettiği toplam su miktarı sorgulanır. Kayıt yoksa 0 ml
			// atanır.
			Integer consumedMl = intakeRepository.getTotalIntakeByDate(client.getUserId(), today);
			if (consumedMl == null) {
				consumedMl = 0;
			}

			// DTO listesine eklenir.
			responseList.add(new ClientWaterTrackingResponse(client.getUserId(), firstName, lastName,
					client.getProfilePhotoUrl(), targetMl, consumedMl));
		}

		return responseList;
	}

	/**
	 * Antrenörün yetkili olduğu sporcunun (öğrencinin) günlük su takip verilerini
	 * getirir. PII kapsamında öğrenci ismi çözülerek aktarılır.
	 * @param clientId Bilgisi istenecek sporcunun benzersiz kimliği
	 * @return ClientWaterTrackingResponse Sporcu su takip bilgisi
	 */
	@Transactional(readOnly = true)
	public ClientWaterTrackingResponse getStudentWaterIntake(Long clientId) {
		// İşlemi yapan güncel koç kullanıcısı alınır.
		AppUser currentUser = userContextService.getCurrentUser();

		// Bilgileri istenen sporcu sorgulanır.
		ClientEntity client = clientRepository.findByUserId(clientId)
			.orElseThrow(() -> new NotFoundException("Sporcu bulunamadı. ID: " + clientId));

		// Güvenlik Kontrolü (Sahiplik): İlgili sporcu bu koça atanmış mı?
		if (client.getCoachId() == null || !client.getCoachId().equals(currentUser.getId())) {
			throw new BadRequestException("Bu sporcunun verilerine erişim yetkiniz yok.");
		}

		// Sistem saati referans alınarak o günün tarihi belirlenir.
		LocalDate today = LocalDate.now(clock);

		// PII gereği veritabanında şifreli tutulan isim deşifre edilmiş olarak gelir ve
		// ad/soyad olarak ayrılır.
		String fullName = client.getFullName();
		String firstName = "";
		String lastName = "";

		if (fullName != null && !fullName.isBlank()) {
			String trimmed = fullName.trim();
			int lastSpace = trimmed.lastIndexOf(' ');
			if (lastSpace == -1) {
				firstName = trimmed;
				lastName = "";
			}
			else {
				firstName = trimmed.substring(0, lastSpace);
				lastName = trimmed.substring(lastSpace + 1);
			}
		}

		// Sporcunun su tüketim hedefi ve o gün tükettiği toplam su miktarı sorgulanır.
		Integer targetMl = targetRepository.findByUserIdAndValidToIsNull(client.getUserId())
			.map(target -> target.getTargetMl())
			.orElse(2500);

		Integer consumedMl = intakeRepository.getTotalIntakeByDate(client.getUserId(), today);
		if (consumedMl == null) {
			consumedMl = 0;
		}

		return new ClientWaterTrackingResponse(client.getUserId(), firstName, lastName, client.getProfilePhotoUrl(),
				targetMl, consumedMl);
	}

}
