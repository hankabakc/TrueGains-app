package com.gym.v2.admin.dto;

/**
 * Kullanici listesinin CSV disa aktarimi.
 * <p>
 * CSV metni {@code ApiResponse} zarfinin icinde doner (KURALLAR §2); dosyayi panel
 * olusturur.
 * </p>
 */
public record AdminUserExportDto(String fileName, int rowCount, String csv) {
}
