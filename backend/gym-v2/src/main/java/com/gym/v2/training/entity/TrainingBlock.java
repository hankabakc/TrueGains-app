package com.gym.v2.training.entity;

import com.gym.v2.auth.entity.AppUser;
import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.List;

/**
 * GYMAPP-V2 Blok Programlama: Antrenman programlarının en üst seviye konteynırı. Bu yapı,
 * bir mesocycle (orta vadeli plan) olarak koçun stratejisini tutar.
 */
@Entity
@Table(name = "training_blocks")
public class TrainingBlock {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false)
	private String name; // Örn: "8 Haftalık Güç Bloğu"

	@Column(length = 2000)
	private String description; // Bloğun amacı ve genel notlar

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "coach_id", nullable = true)
	private AppUser coach; // Programı hazırlayan koç (null ise kişisel program)

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "client_id", nullable = true)
	private AppUser client; // Programın atandığı sporcu

	@Column(nullable = false)
	private Boolean isTemplate = false; // Program bir şablon mu?

	@Column(nullable = false)
	private LocalDate startDate; // Bloğun başlangıç tarihi

	@Column(nullable = false)
	private LocalDate endDate; // Bloğun bitiş tarihi

	@Column(nullable = false)
	private Boolean isActive = true; // Mevcut aktif program mı?

	@Column(name = "duration_weeks", nullable = false)
	private Integer durationWeeks = 4;

	@Column(name = "template_id")
	private Long templateId; // Bu programın türetildiği şablonun ID'si

	@Version
	private Long version;

	@Transient
	private Boolean isOrphaned = false;

	// Bir bloğun içinde birden fazla antrenman günü bulunur.
	@OneToMany(mappedBy = "trainingBlock", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<WorkoutDay> workoutDays;

	// Hibernate için boş constructor
	public TrainingBlock() {
	}

	// Manuel Constructor (Lombok Yasak)
	public TrainingBlock(String name, String description, AppUser coach, AppUser client, LocalDate startDate,
			LocalDate endDate) {
		this.name = name;
		this.description = description;
		this.coach = coach;
		this.client = client;
		this.startDate = startDate;
		this.endDate = endDate;
	}

	// Getter ve Setter'lar
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public AppUser getCoach() {
		return coach;
	}

	public void setCoach(AppUser coach) {
		this.coach = coach;
	}

	public AppUser getClient() {
		return client;
	}

	public void setClient(AppUser client) {
		this.client = client;
	}

	public LocalDate getStartDate() {
		return startDate;
	}

	public void setStartDate(LocalDate startDate) {
		this.startDate = startDate;
	}

	public LocalDate getEndDate() {
		return endDate;
	}

	public void setEndDate(LocalDate endDate) {
		this.endDate = endDate;
	}

	public Boolean getIsActive() {
		return isActive;
	}

	public void setIsActive(Boolean isActive) {
		this.isActive = isActive;
	}

	public Integer getDurationWeeks() {
		return durationWeeks;
	}

	public void setDurationWeeks(Integer durationWeeks) {
		this.durationWeeks = durationWeeks;
	}

	public Boolean getIsTemplate() {
		return isTemplate;
	}

	public void setIsTemplate(Boolean isTemplate) {
		this.isTemplate = isTemplate;
	}

	public List<WorkoutDay> getWorkoutDays() {
		return workoutDays;
	}

	public void setWorkoutDays(List<WorkoutDay> workoutDays) {
		this.workoutDays = workoutDays;
	}

	// Helper methods for bidirectional relationship
	public void addWorkoutDay(WorkoutDay day) {
		if (this.workoutDays == null) {
			this.workoutDays = new java.util.ArrayList<>();
		}
		this.workoutDays.add(day);
		day.setTrainingBlock(this);
	}

	public void removeWorkoutDay(WorkoutDay day) {
		if (this.workoutDays != null) {
			this.workoutDays.remove(day);
			day.setTrainingBlock(null);
		}
	}

	public Long getTemplateId() {
		return templateId;
	}

	public void setTemplateId(Long templateId) {
		this.templateId = templateId;
	}

	public Long getVersion() {
		return version;
	}

	public void setVersion(Long version) {
		this.version = version;
	}

	public Boolean getIsOrphaned() {
		return isOrphaned;
	}

	public void setIsOrphaned(Boolean isOrphaned) {
		this.isOrphaned = isOrphaned;
	}

	@Override
	public boolean equals(Object o) {
		if (this == o) {
			return true;
		}
		if (o == null || getClass() != o.getClass()) {
			return false;
		}
		TrainingBlock that = (TrainingBlock) o;
		return id != null && id.equals(that.id);
	}

	@Override
	public int hashCode() {
		return getClass().hashCode();
	}

}
