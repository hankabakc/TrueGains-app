import 'package:flutter/material.dart';

enum CoachSpecialization {
  all,
  fitness,
  bodybuilding,
  pilates,
  yoga,
  crossfit,
  calisthenics,
  powerlifting,
  conditioning,
  martialArts,
  mobility;

  String get label {
    return switch (this) {
      CoachSpecialization.all => 'Tümü',
      CoachSpecialization.fitness => 'Fitness',
      CoachSpecialization.bodybuilding => 'Vücut Geliştirme',
      CoachSpecialization.pilates => 'Pilates',
      CoachSpecialization.yoga => 'Yoga',
      CoachSpecialization.crossfit => 'Crossfit',
      CoachSpecialization.calisthenics => 'Kalisteniks',
      CoachSpecialization.powerlifting => 'Powerlifting',
      CoachSpecialization.conditioning => 'Kondisyon',
      CoachSpecialization.martialArts => 'Dövüş Sanatları',
      CoachSpecialization.mobility => 'Mobilite',
    };
  }

  String get apiValue {
    return switch (this) {
      CoachSpecialization.all => '',
      CoachSpecialization.fitness => 'Fitness',
      CoachSpecialization.bodybuilding => 'Vücut Geliştirme',
      CoachSpecialization.pilates => 'Pilates',
      CoachSpecialization.yoga => 'Yoga',
      CoachSpecialization.crossfit => 'Crossfit',
      CoachSpecialization.calisthenics => 'Kalisteniks',
      CoachSpecialization.powerlifting => 'Powerlifting',
      CoachSpecialization.conditioning => 'Kondisyon',
      CoachSpecialization.martialArts => 'Dövüş Sanatları',
      CoachSpecialization.mobility => 'Mobilite',
    };
  }

  IconData get icon {
    return switch (this) {
      CoachSpecialization.all => Icons.grid_view,
      CoachSpecialization.fitness => Icons.fitness_center,
      CoachSpecialization.bodybuilding => Icons.sports_gymnastics,
      CoachSpecialization.pilates => Icons.self_improvement_rounded,
      CoachSpecialization.yoga => Icons.spa_rounded,
      CoachSpecialization.crossfit => Icons.sports_gymnastics,
      CoachSpecialization.calisthenics => Icons.accessibility_new,
      CoachSpecialization.powerlifting => Icons.fitness_center,
      CoachSpecialization.conditioning => Icons.directions_run,
      CoachSpecialization.martialArts => Icons.sports_mma,
      CoachSpecialization.mobility => Icons.accessibility_new,
    };
  }
}
