package com.gym.v2.admin.dto;

/**
 * {@code AdminUserRepository.search} satir projeksiyonu.
 * <p>
 * Zaman alanlari {@link OffsetDateTime}: sutunlar TIMESTAMPTZ ve Spring Data yerel sorgu
 * sonucunu bu tiple veriyor. {@code Instant} yazilirsa "Cannot project OffsetDateTime to
 * Instant" ile 500 doner - ustelik yalnizca tabloda KAYIT VARKEN.
 * </p>
 */
public interface AdminUserRowProjection {

	Long getId();

	String getEmail();

	String getFullName();

	String getRole();

	Boolean getActive();

	Boolean getPremium();

	Object getRegisteredAt();

	Object getLastLoginAt();

}
