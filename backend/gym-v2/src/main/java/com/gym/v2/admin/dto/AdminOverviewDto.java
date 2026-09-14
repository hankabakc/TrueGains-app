package com.gym.v2.admin.dto;

/**
 * Yönetim panelinin açılış ekranındaki sayılar.
 * <p>
 * Tamamı <b>salt okunur</b>. Hiçbir alan kişisel veri içermez — yalnızca toplamlar
 * taşınır, bu yüzden bu uçta AES deşifresi yapılmaz.
 * </p>
 *
 * @param totalUsers toplam kayıtlı kullanıcı
 * @param clientCount sporcu sayısı
 * @param coachCount antrenör sayısı
 * @param inactiveUsers hesabı pasifleştirilmiş kullanıcı sayısı
 * @param newLast24h son 24 saatte kaydolan
 * @param newLast7d son 7 günde kaydolan
 * @param newLast30d son 30 günde kaydolan
 * @param activeLast7d son 7 günde en az bir kez giriş yapan
 * @param pairedClients bir antrenöre bağlı sporcu sayısı
 * @param activeSubscriptions süresi dolmamış aktif abonelik sayısı
 */
public record AdminOverviewDto(long totalUsers, long clientCount, long coachCount, long inactiveUsers, long newLast24h,
		long newLast7d, long newLast30d, long activeLast7d, long pairedClients, long activeSubscriptions) {
}
