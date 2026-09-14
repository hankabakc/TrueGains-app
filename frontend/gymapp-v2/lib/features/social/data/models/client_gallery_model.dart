class ClientGalleryModel {
  final int id;
  final String imageUrl;
  final String createdAt;

  ClientGalleryModel({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ClientGalleryModel.fromJson(Map<String, dynamic> json) {
    return ClientGalleryModel(
      id: json['id'] as int,
      imageUrl: json['imageUrl'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}
