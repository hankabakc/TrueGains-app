// ignore_for_file: constant_identifier_names

import 'package:gymapp_v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Kas grubu tanımları — Dart lowerCamelCase convention'a uygun.
/// Backend'den gelen büyük harfli değerler (CHEST, BACK vb.) [fromString] ile eşleştirilir.
/// Her kas grubuna özel renk ve Türkçe isim tanımları bulunur.
enum MuscleGroup {
  CHEST,
  BACK,
  SHOULDERS,
  BICEPS,
  TRICEPS,
  QUADRICEPS,
  HAMSTRINGS,
  CALVES,
  ABS,
  FULL_BODY,
  CARDIO;

  /// Backend JSON'dan gelen büyük harfli string değeri Dart enum'a çevirir.
  static MuscleGroup fromString(String? value) {
    if (value == null) return MuscleGroup.CHEST;
    switch (value.toUpperCase()) {
      case 'CHEST':
        return MuscleGroup.CHEST;
      case 'BACK':
        return MuscleGroup.BACK;
      case 'SHOULDERS':
        return MuscleGroup.SHOULDERS;
      case 'BICEPS':
        return MuscleGroup.BICEPS;
      case 'TRICEPS':
        return MuscleGroup.TRICEPS;
      case 'QUADRICEPS':
        return MuscleGroup.QUADRICEPS;
      case 'HAMSTRINGS':
        return MuscleGroup.HAMSTRINGS;
      case 'CALVES':
        return MuscleGroup.CALVES;
      case 'ABS':
        return MuscleGroup.ABS;
      case 'FULL_BODY':
      case 'FULLBODY':
        return MuscleGroup.FULL_BODY;
      case 'CARDIO':
        return MuscleGroup.CARDIO;
      default:
        return MuscleGroup.CHEST;
    }
  }

  /// Kas grubuna ait Türkçe isim
  String get turkishName {
    switch (this) {
      case MuscleGroup.CHEST:
        return 'Göğüs';
      case MuscleGroup.BACK:
        return 'Sırt';
      case MuscleGroup.SHOULDERS:
        return 'Omuz';
      case MuscleGroup.BICEPS:
        return 'Biceps';
      case MuscleGroup.TRICEPS:
        return 'Triceps';
      case MuscleGroup.QUADRICEPS:
        return 'Ön Bacak';
      case MuscleGroup.HAMSTRINGS:
        return 'Arka Bacak';
      case MuscleGroup.CALVES:
        return 'Kalf';
      case MuscleGroup.ABS:
        return 'Karın';
      case MuscleGroup.FULL_BODY:
        return 'Tüm Vücut';
      case MuscleGroup.CARDIO:
        return 'Kardiyo';
    }
  }

  /// Kas grubuna ait renk kodu
  /// Göğüs: Turuncu, Triceps: Kırmızı, Biceps: Mavi,
  /// Karın: Yeşil, Bacak grupları: Mor tonları
  Color get color {
    switch (this) {
      case MuscleGroup.CHEST:
        return AppColors.muscleChest;
      case MuscleGroup.BACK:
        return AppColors.muscleBack;
      case MuscleGroup.SHOULDERS:
        return AppColors.muscleShoulders;
      case MuscleGroup.BICEPS:
        return AppColors.muscleBiceps;
      case MuscleGroup.TRICEPS:
        return AppColors.muscleTriceps;
      case MuscleGroup.QUADRICEPS:
        return AppColors.muscleQuadriceps;
      case MuscleGroup.HAMSTRINGS:
        return AppColors.muscleHamstrings;
      case MuscleGroup.CALVES:
        return AppColors.muscleCalves;
      case MuscleGroup.ABS:
        return AppColors.muscleAbs;
      case MuscleGroup.FULL_BODY:
        return AppColors.muscleFullBody;
      case MuscleGroup.CARDIO:
        return AppColors.muscleCardio;
    }
  }
}

class Exercise {
  final int id;
  final String name;
  final String? description;
  final MuscleGroup muscleGroup;
  final String? videoUrl;
  final String? imageUrl;
  final String? scientificName;
  final String? targetMuscleDetails;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.muscleGroup,
    this.videoUrl,
    this.imageUrl,
    this.scientificName,
    this.targetMuscleDetails,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] as int?) ?? 0,
      name: (json['name'] as String?) ?? 'İsimsiz Egzersiz',
      description: json['description'] as String?,
      muscleGroup: MuscleGroup.fromString(json['muscleGroup'] as String?),
      videoUrl: json['videoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      scientificName: json['scientificName'] as String?,
      targetMuscleDetails: json['targetMuscleDetails'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup.name,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'scientificName': scientificName,
      'targetMuscleDetails': targetMuscleDetails,
    };
  }
}
