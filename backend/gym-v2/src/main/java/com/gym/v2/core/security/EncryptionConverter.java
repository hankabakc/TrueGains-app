package com.gym.v2.core.security;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * PII (Personal Identifiable Information) verilerini veritabanı seviyesinde AES-256 (GCM)
 * ile şifreler. GCM modu ile veri bütünlüğü ve güvenliği (AEAD) sağlanır. Güvenlik
 * iyileştirmeleri (Byte bazlı anahtar kontrolü ve hata loglama) içerir.
 */
@Converter
@Component
public class EncryptionConverter implements AttributeConverter<String, String> {

	private static final Logger log = LoggerFactory.getLogger(EncryptionConverter.class);

	private static final String ALGORITHM = "AES/GCM/NoPadding";

	private static final int GCM_IV_LENGTH = 12; // 12 bytes

	private static final int GCM_TAG_LENGTH = 128; // 128 bits

	private final SecretKeySpec keySpec;

	private final SecureRandom secureRandom;

	public EncryptionConverter(@Value("${app.security.encryption.key}") String secretKey) {
		if (secretKey == null) {
			throw new IllegalArgumentException("Encryption key cannot be null!");
		}

		// Bulgu #10: Karakter sayısı değil, byte sayısı kontrol edilmelidir (AES-256 için
		// 32 byte).
		byte[] keyBytes = secretKey.getBytes(StandardCharsets.UTF_8);
		if (keyBytes.length != 32) {
			throw new IllegalArgumentException(
					"Kritik Güvenlik Hatası: AES-256 anahtarı tam olarak 32 byte olmalıdır. Mevcut: "
							+ keyBytes.length);
		}

		this.keySpec = new SecretKeySpec(keyBytes, "AES");
		this.secureRandom = new SecureRandom();

		// Başlangıç Logu (Anahtar Uyuşmazlığı Tespiti İçin)
		try {
			java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
			byte[] hash = digest.digest(keyBytes);
			StringBuilder hexString = new StringBuilder();
			for (byte b : hash) {
				String hex = Integer.toHexString(0xff & b);
				if (hex.length() == 1) {
					hexString.append('0');
				}
				hexString.append(hex);
			}
			log.info("[SECURITY] EncryptionConverter başlatıldı. Anahtar SHA-256 parmak izi: {}",
					hexString.toString().substring(0, 8) + "...");
		}
		catch (Exception e) {
			log.warn("[SECURITY] Anahtar parmak izi hesaplanamadı.");
		}
	}

	@Override
	public String convertToDatabaseColumn(String attribute) {
		if (attribute == null) {
			return null;
		}
		return encrypt(attribute);
	}

	@Override
	public String convertToEntityAttribute(String dbData) {
		if (dbData == null) {
			return "";
		}
		try {
			String decrypted = decrypt(dbData);
			return decrypted != null ? decrypted : "";
		}
		catch (Exception e) {
			log.error("[SECURITY] Veritabanı özniteliği deşifre edilirken beklenmeyen hata oluştu. Veri: {}, Sebep: {}",
					dbData, e.getMessage());
			return "";
		}
	}

	/**
	 * Veriyi AES-256 (GCM) ile şifreler.
	 * @param attribute Ham veri
	 * @return Base64 formatında şifreli veri (IV + Ciphertext)
	 */
	public String encrypt(String attribute) {
		if (attribute == null || attribute.isBlank()) {
			return attribute;
		}
		try {
			byte[] iv = new byte[GCM_IV_LENGTH];
			secureRandom.nextBytes(iv);
			GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);

			Cipher cipher = Cipher.getInstance(ALGORITHM);
			cipher.init(Cipher.ENCRYPT_MODE, keySpec, parameterSpec);
			byte[] ciphertext = cipher.doFinal(attribute.getBytes(StandardCharsets.UTF_8));

			byte[] ivWithCiphertext = new byte[iv.length + ciphertext.length];
			System.arraycopy(iv, 0, ivWithCiphertext, 0, iv.length);
			System.arraycopy(ciphertext, 0, ivWithCiphertext, iv.length, ciphertext.length);

			return Base64.getEncoder().encodeToString(ivWithCiphertext);
		}
		catch (Exception e) {
			log.error("[SECURITY] Veri şifreleme hatası: {}", e.getMessage());
			throw new RuntimeException("Veri şifreleme sırasında kritik hata", e);
		}
	}

	/**
	 * Şifreli veriyi çözer. Veri şifreli değilse veya çözülemezse orijinal veriyi döner
	 * (Graceful Degradation).
	 * @param dbData Base64 formatında şifreli veri
	 * @return Deşifre edilmiş veri veya orijinal veri
	 */
	public String decrypt(String dbData) {
		if (dbData == null || dbData.isBlank()) {
			return dbData;
		}
		try {
			byte[] ivWithCiphertext = Base64.getDecoder().decode(dbData);

			if (ivWithCiphertext.length < GCM_IV_LENGTH) {
				return dbData; // Şifreli formatta değil
			}

			byte[] iv = new byte[GCM_IV_LENGTH];
			int ciphertextLength = ivWithCiphertext.length - GCM_IV_LENGTH;
			byte[] ciphertext = new byte[ciphertextLength];

			System.arraycopy(ivWithCiphertext, 0, iv, 0, GCM_IV_LENGTH);
			System.arraycopy(ivWithCiphertext, GCM_IV_LENGTH, ciphertext, 0, ciphertextLength);

			GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH, iv);
			Cipher cipher = Cipher.getInstance(ALGORITHM);
			cipher.init(Cipher.DECRYPT_MODE, keySpec, parameterSpec);

			return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
		}
		catch (Exception e) {
			// Bulgu #11 & #20: Deşifreleme hatası durumunda veriyi bozmak yerine
			// orijinalini dön.
			// Bu, şifrelenmemiş eski verilerin de okunabilmesini sağlar.
			log.debug("[SECURITY] Veri deşifre edilemedi, orijinal veri dönülüyor. Sebep: {}", e.getMessage());
			return dbData;
		}
	}

}
