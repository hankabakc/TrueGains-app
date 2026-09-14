class DietAssignmentModel {
  final int assignmentId;
  final UserSummaryModel user;
  final DietProgramSummaryModel dietProgram;
  final String status;

  DietAssignmentModel({
    required this.assignmentId,
    required this.user,
    required this.dietProgram,
    required this.status,
  });

  // Geriye Dönük Uyumluluk (Compatibility Getters)
  int get studentId => user.id;
  String get fullName => '${user.firstName} ${user.lastName}'.trim();
  String? get profileImageUrl => user.profilePhotoUrl;
  int get assignedProgramId => assignmentId;

  factory DietAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DietAssignmentModel(
      assignmentId: json['assignmentId'] as int,
      user: UserSummaryModel.fromJson(json['user'] as Map<String, dynamic>),
      dietProgram: DietProgramSummaryModel.fromJson(json['dietProgram'] as Map<String, dynamic>),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'user': user.toJson(),
      'dietProgram': dietProgram.toJson(),
      'status': status,
    };
  }
}

class UserSummaryModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;

  UserSummaryModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhotoUrl,
  });

  factory UserSummaryModel.fromJson(Map<String, dynamic> json) {
    return UserSummaryModel(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }
}

class DietProgramSummaryModel {
  final int id;
  final String name;
  final String? startDate;
  final String? endDate;

  DietProgramSummaryModel({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
  });

  factory DietProgramSummaryModel.fromJson(Map<String, dynamic> json) {
    return DietProgramSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}
