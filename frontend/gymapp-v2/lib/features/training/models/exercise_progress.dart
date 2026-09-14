class ExerciseProgress {
  final DateTime date;
  final double oneRepMax;
  final double maxWeight;
  final int totalSets;

  ExerciseProgress({
    required this.date,
    required this.oneRepMax,
    required this.maxWeight,
    required this.totalSets,
  });

  factory ExerciseProgress.fromJson(Map<String, dynamic> json) {
    return ExerciseProgress(
      date: DateTime.parse(json['date'] as String),
      oneRepMax: (json['oneRepMax'] as num).toDouble(),
      maxWeight: (json['maxWeight'] as num).toDouble(),
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
    );
  }
}
