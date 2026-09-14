class CoachStudentProgressModel {
  final int id;
  final int coachId;
  final int clientId;
  final String studentNickname;
  final String beforeImageUrl;
  final String afterImageUrl;
  final String? description;
  final String status;
  final String createdAt;

  CoachStudentProgressModel({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.studentNickname,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory CoachStudentProgressModel.fromJson(Map<String, dynamic> json) {
    return CoachStudentProgressModel(
      id: json['id'] as int,
      coachId: json['coachId'] as int,
      clientId: json['clientId'] as int,
      studentNickname: json['studentNickname'] as String,
      beforeImageUrl: json['beforeImageUrl'] as String,
      afterImageUrl: json['afterImageUrl'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'coachId': coachId,
      'clientId': clientId,
      'studentNickname': studentNickname,
      'beforeImageUrl': beforeImageUrl,
      'afterImageUrl': afterImageUrl,
      'description': description,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
