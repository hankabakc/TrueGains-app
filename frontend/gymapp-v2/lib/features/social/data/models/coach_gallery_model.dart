class CoachGalleryModel {
  final int id;
  final String imageUrl;
  final bool isStudentProgress;
  final DateTime createdAt;

  CoachGalleryModel({
    required this.id,
    required this.imageUrl,
    required this.isStudentProgress,
    required this.createdAt,
  });

  factory CoachGalleryModel.fromJson(Map<String, dynamic> json) {
    return CoachGalleryModel(
      id: json['id'] as int,
      imageUrl: json['imageUrl'] as String,
      isStudentProgress: json['isStudentProgress'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
