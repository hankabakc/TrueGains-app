package com.gym.v2.training.dto;

/**
 * Bir antrenman programına atanmış sporcunun özet bilgilerini taşıyan record.
 *
 * @param studentId Sporcunun benzersiz kimliği
 * @param fullName Sporcunun tam adı
 * @param profileImageUrl Sporcunun profil resmi URL'si
 * @param assignedProgramId Sporcuya atanan program kopyasının benzersiz kimliği
 * @param durationWeeks Programın hafta bazında süresi
 * @param weeksElapsed Programın atanmasından itibaren geçen hafta sayısı
 * @param isActive Programın aktiflik durumu
 */
public record AssignedStudentSummaryRecord(Long studentId, String fullName, String profileImageUrl,
		Long assignedProgramId, Integer durationWeeks, Integer weeksElapsed, Boolean isActive) {
}
