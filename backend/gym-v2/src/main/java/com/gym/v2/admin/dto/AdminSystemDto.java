package com.gym.v2.admin.dto;

/**
 * Sunucunun o anki calisma durumu.
 * <p>
 * Veri Micrometer kayit defterinden <b>surec ici</b> okunuyor; Prometheus'a ya da baska
 * bir servise ag cagrisi yapilmiyor. Boylece panel, izleme yigini ayakta olmasa bile
 * sunucunun durumunu gosterebiliyor.
 * </p>
 * <p>
 * Sayaclar surecin acilisindan beri KUMULATIF. Egilim (trend) gerekirse Prometheus
 * sorgulanir; bu uc "su anda ne durumdayiz" sorusunu cevaplar.
 * </p>
 *
 * @param uptimeSeconds surecin ayakta kalma suresi
 * @param processCpuPercent bu surecin CPU kullanimi (yuzde)
 * @param systemCpuPercent makinenin toplam CPU kullanimi (yuzde)
 * @param heapUsedBytes kullanilan yigin bellegi
 * @param heapMaxBytes ayrilabilir en fazla yigin bellegi
 * @param dbActive kullanimdaki veritabani baglantisi
 * @param dbIdle bosta bekleyen baglanti
 * @param dbMax havuzun ust siniri
 * @param dbPending baglanti bekleyen istek sayisi (0 olmali)
 * @param requestsTotal acilistan beri islenen istek
 * @param serverErrorsTotal 5xx ile biten istek
 * @param clientErrorsTotal 4xx ile biten istek
 * @param avgResponseMs ortalama yanit suresi
 * @param maxResponseMs gorulen en yuksek yanit suresi
 */
public record AdminSystemDto(double uptimeSeconds, double processCpuPercent, double systemCpuPercent,
		long heapUsedBytes, long heapMaxBytes, int dbActive, int dbIdle, int dbMax, int dbPending, long requestsTotal,
		long serverErrorsTotal, long clientErrorsTotal, double avgResponseMs, double maxResponseMs) {
}
