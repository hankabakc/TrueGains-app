package com.gym.v2.auth.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Kullanıcıların oturumlarını şifre girmeden yenilemelerini sağlayan yenileme
 * token'larını (Refresh Token) temsil eden JPA varlık sınıfı.
 * <p>
 * Kısa süreli erişim token'ları (Access Token) süresi dolduğunda, istemci elindeki
 * yenileme token'ı ile sunucuya başvurarak yeni bir erişim token'ı alabilir.
 * </p>
 *
 * <h2>Nasıl Çalışır?</h2> Her yenileme token'ı bir kullanıcıyla ({@link AppUser}) ve
 * isteğe bağlı olarak bir cihaz kimliğiyle ({@code device_id}) ilişkilendirilir. Token'ın
 * son kullanma tarihi kontrol edilerek geçerliliği doğrulanır.
 *
 * <h2>Neden Bu Sınıf Var?</h2> Güvenlik ve kullanıcı deneyimi arasında bir denge kurmak
 * için tasarlanmıştır. Erişimi kısa süreli token'larla kısıtlarken, kullanıcının her
 * seferinde giriş yapma zahmetinden kurtulmasını sağlar.
 */
@Entity
@Table(name = "refresh_token", indexes = { @Index(name = "idx_refresh_token_value", columnList = "token"),
		@Index(name = "idx_refresh_token_user", columnList = "user_id") })
public class RefreshToken {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false, unique = true)
	private String token;

	@Column(name = "device_id")
	private String deviceId;

	@ManyToOne
	@JoinColumn(name = "user_id", referencedColumnName = "id")
	private AppUser user;

	@Column(name = "expiry_date", nullable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant expiryDate;

	/**
	 * JPA için gerekli boş yapılandırıcı.
	 */
	public RefreshToken() {
		// JPA tarafından kullanım için gereklidir.
	}

	public Long getId() {
		return id;
	}

	/**
	 * @return Yenileme token'ı karakter dizisi.
	 */
	public String getToken() {
		return token;
	}

	/**
	 * @param token Token karakter dizisi set edilir.
	 */
	public void setToken(String token) {
		this.token = token;
	}

	/**
	 * @return Token'ın hangi cihazda üretildiği bilgisi.
	 */
	public String getDeviceId() {
		return deviceId;
	}

	/**
	 * @param deviceId Cihaz kimliği set edilir.
	 */
	public void setDeviceId(String deviceId) {
		this.deviceId = deviceId;
	}

	/**
	 * @return Token'ın ait olduğu kullanıcı nesnesi.
	 */
	public AppUser getUser() {
		return user;
	}

	/**
	 * @param user Kullanıcı nesnesi set edilir.
	 */
	public void setUser(AppUser user) {
		this.user = user;
	}

	/**
	 * @return Token'ın sona ereceği zaman dilimi.
	 */
	public Instant getExpiryDate() {
		return expiryDate;
	}

	/**
	 * @param expiryDate Sona erme tarihi set edilir.
	 */
	public void setExpiryDate(Instant expiryDate) {
		this.expiryDate = expiryDate;
	}

}
