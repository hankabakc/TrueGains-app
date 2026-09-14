package com.gym.v2.training.entity;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * GYMAPP-V2 Egzersiz Kütüphanesi: Sistemdeki tüm sabit egzersizlerin (Bench Press vb.)
 * tanımı. Koçlar program oluştururken bu kütüphaneden seçim yapacaktır.
 */
@Entity
@Table(name = "exercises")
public class Exercise {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(nullable = false)
	private String name; // Egzersiz Adı

	@Column(length = 1000)
	private String description; // Nasıl yapılır? (Açıklama)

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private MuscleGroup muscleGroup; // Hedef Kas Grubu

	private String videoUrl; // Uygulama videosu linki (YouTube/S3)

	private String imageUrl; // Egzersiz görseli linki

	@Column(name = "scientific_name")
	private String scientificName; // Bilimsel kas ismi (Örn: Pectoralis Major)

	@Column(name = "target_muscle_details", length = 2000)
	private String targetMuscleDetails; // Detaylı hedef kas açıklaması

	@Column(nullable = false, updatable = false, columnDefinition = "TIMESTAMPTZ")
	private Instant createdAt;

	/**
	 * Zaman damgasını dışarıdan (Service/Clock) atamak için kullanılır.
	 * @param now Mevcut zaman
	 */
	public void onPersist(Instant now) {
		this.createdAt = now;
	}

	// Hibernate için boş constructor
	// Hibernate için boş constructor
	public Exercise() {
	}

	// Manuel Constructor (Lombok Yasak)
	public Exercise(String name, String description, MuscleGroup muscleGroup, String videoUrl, String imageUrl) {
		this.name = name;
		this.description = description;
		this.muscleGroup = muscleGroup;
		this.videoUrl = videoUrl;
		this.imageUrl = imageUrl;
	}

	// Getter ve Setter'lar (Lombok Yasak)
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

	public MuscleGroup getMuscleGroup() {
		return muscleGroup;
	}

	public void setMuscleGroup(MuscleGroup muscleGroup) {
		this.muscleGroup = muscleGroup;
	}

	public String getVideoUrl() {
		return videoUrl;
	}

	public void setVideoUrl(String videoUrl) {
		this.videoUrl = videoUrl;
	}

	public String getImageUrl() {
		return imageUrl;
	}

	public void setImageUrl(String imageUrl) {
		this.imageUrl = imageUrl;
	}

	public String getScientificName() {
		return scientificName;
	}

	public void setScientificName(String scientificName) {
		this.scientificName = scientificName;
	}

	public String getTargetMuscleDetails() {
		return targetMuscleDetails;
	}

	public void setTargetMuscleDetails(String targetMuscleDetails) {
		this.targetMuscleDetails = targetMuscleDetails;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

}
