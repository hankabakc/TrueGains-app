import 'package:equatable/equatable.dart';

class WaterDailySummaryModel extends Equatable {
  final int totalIntakeMl;
  final int targetMl;
  final List<WaterIntakeModel> intakes;
  final List<CustomGlassModel> customGlasses;

  const WaterDailySummaryModel({
    required this.totalIntakeMl,
    required this.targetMl,
    required this.intakes,
    required this.customGlasses,
  });

  factory WaterDailySummaryModel.fromJson(Map<String, dynamic> json) {
    return WaterDailySummaryModel(
      totalIntakeMl: json['totalIntakeMl'] as int,
      targetMl: json['targetMl'] as int,
      intakes:
          (json['intakes'] as List)
              .map((e) => WaterIntakeModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      customGlasses:
          (json['customGlasses'] as List)
              .map((e) => CustomGlassModel.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  List<Object?> get props => [totalIntakeMl, targetMl, intakes, customGlasses];
}

class WaterIntakeModel extends Equatable {
  final int id;
  final int amountMl;
  final DateTime date;
  final DateTime createdAt;

  const WaterIntakeModel({
    required this.id,
    required this.amountMl,
    required this.date,
    required this.createdAt,
  });

  factory WaterIntakeModel.fromJson(Map<String, dynamic> json) {
    return WaterIntakeModel(
      id: json['id'] as int,
      amountMl: json['amountMl'] as int,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, amountMl, date, createdAt];
}

class CustomGlassModel extends Equatable {
  final int id;
  final String name;
  final int sizeMl;

  const CustomGlassModel({
    required this.id,
    required this.name,
    required this.sizeMl,
  });

  factory CustomGlassModel.fromJson(Map<String, dynamic> json) {
    return CustomGlassModel(
      id: json['id'] as int,
      name: json['name'] as String,
      sizeMl: json['sizeMl'] as int,
    );
  }

  @override
  List<Object?> get props => [id, name, sizeMl];
}

class WaterDailyTotalModel extends Equatable {
  final DateTime date;
  final int totalIntakeMl;
  final int targetMl;

  const WaterDailyTotalModel({
    required this.date,
    required this.totalIntakeMl,
    required this.targetMl,
  });

  factory WaterDailyTotalModel.fromJson(Map<String, dynamic> json) {
    return WaterDailyTotalModel(
      date: DateTime.parse(json['date'] as String),
      totalIntakeMl: json['totalIntakeMl'] as int,
      targetMl: json['targetMl'] as int,
    );
  }

  @override
  List<Object?> get props => [date, totalIntakeMl, targetMl];
}
