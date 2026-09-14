class PairingRequestModel {
  final int id;
  final int clientId;
  final String? clientFullName;
  final int coachId;
  final String? coachFullName;
  final String status;
  final String? message;
  final DateTime? createdAt;
  final int? version;

  PairingRequestModel({
    required this.id,
    required this.clientId,
    this.clientFullName,
    required this.coachId,
    this.coachFullName,
    required this.status,
    this.message,
    this.createdAt,
    this.version,
  });

  factory PairingRequestModel.fromJson(Map<String, dynamic> json) {
    return PairingRequestModel(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientFullName: json['clientFullName'] as String?,
      coachId: json['coachId'] as int,
      coachFullName: json['coachFullName'] as String?,
      status: json['status'] as String,
      message: json['message'] as String?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      version: json['version'] as int?,
    );
  }
}
