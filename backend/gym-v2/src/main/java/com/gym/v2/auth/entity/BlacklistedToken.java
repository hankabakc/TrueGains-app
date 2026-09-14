package com.gym.v2.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;

/**
 * Kara listeye alınmış (geçersiz kılınmış) JWT token'larını temsil eden JPA varlık
 * sınıfı.
 * <p>
 * Kullanıcı çıkış yaptığında (logout), mevcut erişim token'ı bu tabloya kaydedilir ve
 * süresi dolana kadar sistem tarafından reddedilir.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> Her istekte, gelen token bu tablodaki kayıtlarla
 * karşılaştırılır. Eğer eşleşme varsa, token teknik olarak geçerli olsa bile (imzası
 * doğru olsa bile) yetkilendirme başarısız olur.
 *
 * <h2>Neden Bu Sınıf Var?</h2> JWT token'lar doğası gereği stateless (durumsuz) olduğu
 * için, sunucu tarafında bir token'ı süresi dolmadan iptal etmenin yolu bu token'ları bir
 * kara listede takip etmektir.
 */
@Entity
@Table(name = "blacklisted_token", indexes = { @Index(name = "idx_blacklisted_jti", columnList = "jti") })
public class BlacklistedToken {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Version
	private Long version;

	@Column(name = "jti", nullable = false, unique = true, length = 36)
	private String jti;

	@Column(name = "expiry_date", nullable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant expiryDate;

	/**
	 * Varsayılan yapılandırıcı. JPA gereksinimi için eklenmiştir. Dışarıdan izinsiz nesne
	 * üretimini engellemek için protected yapılmıştır.
	 */
	protected BlacklistedToken() {
	}

	/**
	 * Belirli bir token ve son kullanma tarihi ile yeni bir kayıt oluşturur.
	 * @param token Kara listeye alınacak JWT karakter dizisi.
	 * @param expiryDate Token'ın normal şartlarda sona ereceği zaman dilimi.
	 */
	public BlacklistedToken(String jti, Instant expiryDate) {
		this.jti = jti;
		this.expiryDate = expiryDate;
	}

	/**
	 * @return Kaydın benzersiz veritabanı kimliği.
	 */
	public Long getId() {
		return id;
	}

	public Long getVersion() {
		return version;
	}

	public String getJti() {
		return jti;
	}

	public Instant getExpiryDate() {
		return expiryDate;
	}

}
