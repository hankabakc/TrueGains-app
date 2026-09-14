package com.gym.v2.measurement.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;

/**
 * GYMAPP-V2 Ölçüm Entity'si. Kullanıcıların kilo, yağ oranı ve bölgesel vücut ölçülerini
 * tarih bazlı olarak kaydeder. Her kayıt bir "anlık görüntü" (snapshot) niteliğindedir ve
 * gelişim grafiklerinin veri kaynağını oluşturur.
 *
 * Pure Java Politikası: Lombok kullanılmaz, tüm getter/setter'lar manueldir.
 */
@Entity
@Table(name = "measurements")
public class Measurement {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	// Ölçümın sahibi olan kullanıcı
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id", nullable = false)
	private AppUser user;

	// --- Temel Metrikler ---

	@Column(precision = 5, scale = 2)
	private BigDecimal weight; // Kilo (kg)

	@Column(precision = 5, scale = 2)
	private BigDecimal height; // Boy (cm)

	@Column(name = "body_fat_pct", precision = 4, scale = 1)
	private BigDecimal bodyFatPct; // Yağ oranı (%)

	@Column(name = "muscle_mass", precision = 5, scale = 2)
	private BigDecimal muscleMass; // Kas kütlesi (kg)

	// --- Bölgesel Ölçüler (cm) ---

	@Column(precision = 5, scale = 1)
	private BigDecimal chest; // Göğüs çevresi

	@Column(precision = 5, scale = 1)
	private BigDecimal waist; // Bel çevresi

	@Column(precision = 5, scale = 1)
	private BigDecimal shoulders; // Omuz çevresi

	@Column(name = "left_arm", precision = 5, scale = 1)
	private BigDecimal leftArm; // Sol kol çevresi

	@Column(name = "right_arm", precision = 5, scale = 1)
	private BigDecimal rightArm; // Sağ kol çevresi

	@Column(name = "left_leg", precision = 5, scale = 1)
	private BigDecimal leftLeg; // Sol bacak çevresi

	@Column(name = "right_leg", precision = 5, scale = 1)
	private BigDecimal rightLeg; // Sağ bacak çevresi

	@Column(precision = 5, scale = 1)
	private BigDecimal hips; // Kalça çevresi

	// --- Ek Bilgiler ---

	@Column(length = 500)
	private String notes; // Kullanıcı notları

	@Column(name = "created_at", nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	// Antrenörle paylaşılma durumu
	@Column(name = "is_shared_with_coach", nullable = false)
	private Boolean isSharedWithCoach = false;

	@PrePersist
	protected void onCreate() {
		this.createdAt = Instant.now();
	}

	// ===================== GETTER & SETTER =====================

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public AppUser getUser() {
		return user;
	}

	public void setUser(AppUser user) {
		this.user = user;
	}

	public BigDecimal getWeight() {
		return weight;
	}

	public void setWeight(BigDecimal weight) {
		this.weight = weight;
	}

	public BigDecimal getHeight() {
		return height;
	}

	public void setHeight(BigDecimal height) {
		this.height = height;
	}

	public BigDecimal getBodyFatPct() {
		return bodyFatPct;
	}

	public void setBodyFatPct(BigDecimal bodyFatPct) {
		this.bodyFatPct = bodyFatPct;
	}

	public BigDecimal getMuscleMass() {
		return muscleMass;
	}

	public void setMuscleMass(BigDecimal muscleMass) {
		this.muscleMass = muscleMass;
	}

	public BigDecimal getChest() {
		return chest;
	}

	public void setChest(BigDecimal chest) {
		this.chest = chest;
	}

	public BigDecimal getWaist() {
		return waist;
	}

	public void setWaist(BigDecimal waist) {
		this.waist = waist;
	}

	public BigDecimal getShoulders() {
		return shoulders;
	}

	public void setShoulders(BigDecimal shoulders) {
		this.shoulders = shoulders;
	}

	public BigDecimal getLeftArm() {
		return leftArm;
	}

	public void setLeftArm(BigDecimal leftArm) {
		this.leftArm = leftArm;
	}

	public BigDecimal getRightArm() {
		return rightArm;
	}

	public void setRightArm(BigDecimal rightArm) {
		this.rightArm = rightArm;
	}

	public BigDecimal getLeftLeg() {
		return leftLeg;
	}

	public void setLeftLeg(BigDecimal leftLeg) {
		this.leftLeg = leftLeg;
	}

	public BigDecimal getRightLeg() {
		return rightLeg;
	}

	public void setRightLeg(BigDecimal rightLeg) {
		this.rightLeg = rightLeg;
	}

	public BigDecimal getHips() {
		return hips;
	}

	public void setHips(BigDecimal hips) {
		this.hips = hips;
	}

	public String getNotes() {
		return notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Boolean getIsSharedWithCoach() {
		return isSharedWithCoach;
	}

	public void setIsSharedWithCoach(Boolean isSharedWithCoach) {
		this.isSharedWithCoach = isSharedWithCoach;
	}

}
