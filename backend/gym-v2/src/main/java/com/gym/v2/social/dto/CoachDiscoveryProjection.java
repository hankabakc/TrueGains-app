package com.gym.v2.social.dto;

/**
 * Keşfet pazaryeri koç sorgusu için Spring Data JPA projeksiyon arayüzü. N+1 sorgu
 * problemini önlemek ve veritabanı düzeyinde toplu (aggregate) hesaplama yapmak amacıyla
 * kullanılır.
 */
public interface CoachDiscoveryProjection {

	Long getUserId();

	String getFullName();

	String getBio();

	String getSpecialization();

	String getCurrency();

	String getProfilePhotoUrl();

	String getInstagramUrl();

	String getProvince();

	String getDistrict();

	Integer getExperienceYears();

	java.math.BigDecimal getMinPackagePrice();

	Integer getProfileScore();

	Double getAverageRating();

	Integer getReviewCount();

	Integer getActiveStudentCount();

}
