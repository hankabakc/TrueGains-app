package com.gym.v2.social.service;

import com.gym.v2.auth.entity.AppUser;
import com.gym.v2.auth.entity.UserRole;
import com.gym.v2.auth.repository.ClientRepository;
import com.gym.v2.auth.repository.CoachRepository;
import com.gym.v2.core.security.EncryptionConverter;
import org.mapstruct.Named;
import org.springframework.stereotype.Component;

/**
 * SocialMapper için karmaşık veri çözümleme ve decryption işlemlerini yöneten yardımcı
 * bileşen.
 */
@Component
public class SocialMappingHelper {

	private final EncryptionConverter encryptionConverter;

	private final ClientRepository clientRepository;

	private final CoachRepository coachRepository;

	public SocialMappingHelper(EncryptionConverter encryptionConverter, ClientRepository clientRepository,
			CoachRepository coachRepository) {
		this.encryptionConverter = encryptionConverter;
		this.clientRepository = clientRepository;
		this.coachRepository = coachRepository;
	}

	@Named("resolveClientName")
	public String resolveClientName(Long userId) {
		if (userId == null) {
			return "Sporcu";
		}
		return clientRepository.findByUserId(userId).map(c -> c.getFullName()).orElse("Sporcu");
	}

	@Named("resolveCoachName")
	public String resolveCoachName(Long userId) {
		if (userId == null) {
			return "Antrenör";
		}
		return coachRepository.findByUserId(userId).map(c -> c.getFullName()).orElse("Antrenör");
	}

	@Named("resolveSenderFullName")
	public String resolveSenderFullName(AppUser sender) {
		if (sender == null) {
			return "Bilinmeyen Kullanıcı";
		}
		if (UserRole.CLIENT.equals(sender.getRole())) {
			return resolveClientName(sender.getId());
		}
		else if (UserRole.COACH.equals(sender.getRole())) {
			return resolveCoachName(sender.getId());
		}
		return "Bilinmeyen Kullanıcı";
	}

	@Named("decrypt")
	public String decrypt(String encryptedValue) {
		return encryptionConverter.decrypt(encryptedValue);
	}

	@Named("identity")
	public String identity(String value) {
		return value;
	}

}
