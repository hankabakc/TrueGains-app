/// Koç paneli "Atanan Programlar" sekmesi için kullanılan veri modelleri.
class AssignedStudentSummary {

	final int studentId;

	final String fullName;

	final String? profileImageUrl;

	final int? assignedProgramId;

	final int durationWeeks;

	final int weeksElapsed;

	final bool isActive;

	AssignedStudentSummary({
		required this.studentId,
		required this.fullName,
		this.profileImageUrl,
		this.assignedProgramId,
		this.durationWeeks = 4,
		this.weeksElapsed = 0,
		this.isActive = false,
	});

	factory AssignedStudentSummary.fromJson(Map<String, dynamic> json) {
		return AssignedStudentSummary(
			studentId: json['studentId'] as int,
			fullName: json['fullName'] as String,
			profileImageUrl: json['profileImageUrl'] as String?,
			assignedProgramId: json['assignedProgramId'] as int?,
			durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 4,
			weeksElapsed: (json['weeksElapsed'] as num?)?.toInt() ?? 0,
			isActive: (json['isActive'] as bool?) ?? false,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'studentId': studentId,
			'fullName': fullName,
			'profileImageUrl': profileImageUrl,
			'assignedProgramId': assignedProgramId,
			'durationWeeks': durationWeeks,
			'weeksElapsed': weeksElapsed,
			'isActive': isActive,
		};
	}

}

class ProgramWithAssignments {

	final int programId;

	final String programName;

	final String? programDescription;

	final List<AssignedStudentSummary> assignedStudents;

	ProgramWithAssignments({
		required this.programId,
		required this.programName,
		this.programDescription,
		required this.assignedStudents,
	});

	factory ProgramWithAssignments.fromJson(Map<String, dynamic> json) {
		return ProgramWithAssignments(
			programId: json['programId'] as int,
			programName: json['programName'] as String,
			programDescription: json['programDescription'] as String?,
			assignedStudents: (json['assignedStudents'] as List)
				.map((s) => AssignedStudentSummary.fromJson(s as Map<String, dynamic>))
				.toList(),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'programId': programId,
			'programName': programName,
			'programDescription': programDescription,
			'assignedStudents': assignedStudents.map((s) => s.toJson()).toList(),
		};
	}

}
