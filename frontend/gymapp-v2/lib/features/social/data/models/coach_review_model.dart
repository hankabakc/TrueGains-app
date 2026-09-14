class CoachReviewModel {
  final int id;
  final int clientId;
  final String clientName;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? packageName;

  CoachReviewModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.packageName,
  });

  factory CoachReviewModel.fromJson(Map<String, dynamic> json) {
    return CoachReviewModel(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      packageName: json['packageName'] as String?,
    );
  }
}
