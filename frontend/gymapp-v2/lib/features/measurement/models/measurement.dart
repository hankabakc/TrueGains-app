/// GYMAPP-V2 Ölçüm Modeli.
/// Backend MeasurementDTO ile birebir eşleşir.
/// Tüm bölgesel ölçüler opsiyoneldir (nullable).
class Measurement {
  final int? id;
  final double? weight; // Kilo (kg)
  final double? height; // Boy (cm)
  final double? bodyFatPct; // Yağ oranı (%)
  final double? muscleMass; // Kas kütlesi (kg)
  final double? chest; // Göğüs çevresi (cm)
  final double? waist; // Bel çevresi (cm)
  final double? shoulders; // Omuz çevresi (cm)
  final double? leftArm; // Sol kol çevresi (cm)
  final double? rightArm; // Sağ kol çevresi (cm)
  final double? leftLeg; // Sol bacak çevresi (cm)
  final double? rightLeg; // Sağ bacak çevresi (cm)
  final double? hips; // Kalça çevresi (cm)
  final String? notes; // Kullanıcı notları
  final DateTime? createdAt; // Ölçüm tarihi
  final bool isSharedWithCoach; // Antrenörle paylaşılma durumu

  Measurement({
    this.id,
    this.weight,
    this.height,
    this.bodyFatPct,
    this.muscleMass,
    this.chest,
    this.waist,
    this.shoulders,
    this.leftArm,
    this.rightArm,
    this.leftLeg,
    this.rightLeg,
    this.hips,
    this.notes,
    this.createdAt,
    this.isSharedWithCoach = false,
  });

  /// JSON → Measurement dönüşümü (API'den gelen veri)
  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as int?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bodyFatPct: (json['bodyFatPct'] as num?)?.toDouble(),
      muscleMass: (json['muscleMass'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      shoulders: (json['shoulders'] as num?)?.toDouble(),
      leftArm: (json['leftArm'] as num?)?.toDouble(),
      rightArm: (json['rightArm'] as num?)?.toDouble(),
      leftLeg: (json['leftLeg'] as num?)?.toDouble(),
      rightLeg: (json['rightLeg'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      isSharedWithCoach: json['isSharedWithCoach'] as bool? ?? false,
    );
  }

  /// Measurement → JSON dönüşümü (API'ye gönderilecek veri)
  Map<String, dynamic> toJson() {
    return {
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bodyFatPct != null) 'bodyFatPct': bodyFatPct,
      if (muscleMass != null) 'muscleMass': muscleMass,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (shoulders != null) 'shoulders': shoulders,
      if (leftArm != null) 'leftArm': leftArm,
      if (rightArm != null) 'rightArm': rightArm,
      if (leftLeg != null) 'leftLeg': leftLeg,
      if (rightLeg != null) 'rightLeg': rightLeg,
      if (hips != null) 'hips': hips,
      if (notes != null) 'notes': notes,
    };
  }

  Measurement copyWith({
    int? id,
    double? weight,
    double? height,
    double? bodyFatPct,
    double? muscleMass,
    double? chest,
    double? waist,
    double? shoulders,
    double? leftArm,
    double? rightArm,
    double? leftLeg,
    double? rightLeg,
    double? hips,
    String? notes,
    DateTime? createdAt,
    bool? isSharedWithCoach,
  }) {
    return Measurement(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPct: bodyFatPct ?? this.bodyFatPct,
      muscleMass: muscleMass ?? this.muscleMass,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      shoulders: shoulders ?? this.shoulders,
      leftArm: leftArm ?? this.leftArm,
      rightArm: rightArm ?? this.rightArm,
      leftLeg: leftLeg ?? this.leftLeg,
      rightLeg: rightLeg ?? this.rightLeg,
      hips: hips ?? this.hips,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isSharedWithCoach: isSharedWithCoach ?? this.isSharedWithCoach,
    );
  }
}
