package com.gym.v2.training.dto;

import java.util.List;

/**
 * Bir antrenman programı şablonunu ve ona atanmış olan sporcuların listesini taşıyan
 * record.
 *
 * @param programId Programın (şablonun) benzersiz kimliği
 * @param programName Programın adı
 * @param programDescription Programın açıklaması
 * @param assignedStudents Programa atanmış olan sporcuların listesi
 */
public record ProgramWithAssignmentsRecord(Long programId, String programName, String programDescription,
		List<AssignedStudentSummaryRecord> assignedStudents) {
}
