package com.gym.v2.nutrition.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Diyet Programı Entity (DietProgram) Kullanıcı veya antrenör tarafından oluşturulan
 * programları temsil eder.
 */
@Entity
@Table(name = "diet_program")
public class DietProgram {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Version
	private Long version;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "owner_id", nullable = false)
	private AppUser owner;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id")
	private AppUser coach;

	@Column(nullable = false)
	private String name;

	@Column(name = "is_main")
	private boolean main;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private DietSource source;

	@Column(name = "is_template")
	private boolean template;

	@Column(name = "original_template_id")
	private Long originalTemplateId;

	@Transient
	private boolean orphaned;

	@Column(name = "created_at", updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	@Column(name = "updated_at", columnDefinition = "TIMESTAMPTZ")
	private Instant updatedAt;

	public void onPersist(Instant now) {
		this.createdAt = now;
		this.updatedAt = now;
	}

	public void onUpdate(Instant now) {
		this.updatedAt = now;
	}

	@Column(name = "target_calories")
	private BigDecimal targetCalories = BigDecimal.ZERO;

	@Column(name = "target_protein")
	private BigDecimal targetProtein = BigDecimal.ZERO;

	@Column(name = "target_carbs")
	private BigDecimal targetCarbs = BigDecimal.ZERO;

	@Column(name = "target_fat")
	private BigDecimal targetFat = BigDecimal.ZERO;

	@Column(name = "target_sugar")
	private BigDecimal targetSugar = BigDecimal.ZERO;

	@Column(name = "target_fiber")
	private BigDecimal targetFiber = BigDecimal.ZERO;

	@Column(name = "target_sodium")
	private BigDecimal targetSodium = BigDecimal.ZERO;

	@Column(name = "target_cholesterol")
	private BigDecimal targetCholesterol = BigDecimal.ZERO;

	@Column(name = "target_potassium")
	private BigDecimal targetPotassium = BigDecimal.ZERO;

	@OneToMany(mappedBy = "dietProgram", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<DietDay> dietDays = new ArrayList<>();

	// --- Constructors ---

	public DietProgram() {
	}

	public DietProgram(AppUser owner, String name, DietSource source) {
		this();
		this.owner = owner;
		this.name = name;
		this.source = source;
	}

	// --- Getters & Setters ---

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Long getVersion() {
		return version;
	}

	public AppUser getOwner() {
		return owner;
	}

	public void setOwner(AppUser owner) {
		this.owner = owner;
	}

	public AppUser getCoach() {
		return coach;
	}

	public void setCoach(AppUser coach) {
		this.coach = coach;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public boolean isMain() {
		return main;
	}

	public void setMain(boolean main) {
		this.main = main;
	}

	public DietSource getSource() {
		return source;
	}

	public void setSource(DietSource source) {
		this.source = source;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

	public boolean isTemplate() {
		return template;
	}

	public void setTemplate(boolean template) {
		this.template = template;
	}

	public List<DietDay> getDietDays() {
		return dietDays;
	}

	public void setDietDays(List<DietDay> dietDays) {
		this.dietDays = dietDays;
	}

	public void addDietDay(DietDay dietDay) {
		dietDays.add(dietDay);
		dietDay.setDietProgram(this);
	}

	public BigDecimal getTargetCalories() {
		return targetCalories;
	}

	public void setTargetCalories(BigDecimal targetCalories) {
		this.targetCalories = targetCalories;
	}

	public BigDecimal getTargetProtein() {
		return targetProtein;
	}

	public void setTargetProtein(BigDecimal targetProtein) {
		this.targetProtein = targetProtein;
	}

	public BigDecimal getTargetCarbs() {
		return targetCarbs;
	}

	public void setTargetCarbs(BigDecimal targetCarbs) {
		this.targetCarbs = targetCarbs;
	}

	public BigDecimal getTargetFat() {
		return targetFat;
	}

	public void setTargetFat(BigDecimal targetFat) {
		this.targetFat = targetFat;
	}

	public BigDecimal getTargetSugar() {
		return targetSugar;
	}

	public void setTargetSugar(BigDecimal targetSugar) {
		this.targetSugar = targetSugar;
	}

	public BigDecimal getTargetFiber() {
		return targetFiber;
	}

	public void setTargetFiber(BigDecimal targetFiber) {
		this.targetFiber = targetFiber;
	}

	public BigDecimal getTargetSodium() {
		return targetSodium;
	}

	public void setTargetSodium(BigDecimal targetSodium) {
		this.targetSodium = targetSodium;
	}

	public BigDecimal getTargetCholesterol() {
		return targetCholesterol;
	}

	public void setTargetCholesterol(BigDecimal targetCholesterol) {
		this.targetCholesterol = targetCholesterol;
	}

	public BigDecimal getTargetPotassium() {
		return targetPotassium;
	}

	public void setTargetPotassium(BigDecimal targetPotassium) {
		this.targetPotassium = targetPotassium;
	}

	public Long getOriginalTemplateId() {
		return originalTemplateId;
	}

	public void setOriginalTemplateId(Long originalTemplateId) {
		this.originalTemplateId = originalTemplateId;
	}

	public boolean isOrphaned() {
		return orphaned;
	}

	public void setOrphaned(boolean orphaned) {
		this.orphaned = orphaned;
	}

}
