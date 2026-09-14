/// Antrenörle paylaşılan tekil bir ölçüm kaydı modeli.
class SharedMeasurement {
  final int id;
  final double? weight;
  final double? height;
  final double? bodyFatPct;
  final double? muscleMass;
  final double? chest;
  final double? waist;
  final double? shoulders;
  final double? leftArm;
  final double? rightArm;
  final double? leftLeg;
  final double? rightLeg;
  final double? hips;
  final String? notes;
  final DateTime measurementDate;

  SharedMeasurement({
    required this.id,
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
    required this.measurementDate,
  });

  factory SharedMeasurement.fromJson(Map<String, dynamic> json) {
    return SharedMeasurement(
      id: json['id'] as int,
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
      measurementDate: DateTime.parse(json['measurementDate'] as String).toLocal(),
    );
  }
}
