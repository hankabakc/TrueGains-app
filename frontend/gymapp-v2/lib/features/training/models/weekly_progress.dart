class WeeklyProgress {
  final int targetDays;
  final int completedDays;
  final double successPercentage;

  WeeklyProgress({
    required this.targetDays,
    required this.completedDays,
    required this.successPercentage,
  });

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      targetDays: json['targetDays'] as int? ?? 0,
      completedDays: json['completedDays'] as int? ?? 0,
      successPercentage: (json['successPercentage'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetDays': targetDays,
      'completedDays': completedDays,
      'successPercentage': successPercentage,
    };
  }
}

class WeeklyHistoryItem {
  final DateTime weekStartDate;
  final int targetDays;
  final int completedDays;
  final double successPercentage;

  WeeklyHistoryItem({
    required this.weekStartDate,
    required this.targetDays,
    required this.completedDays,
    required this.successPercentage,
  });

  factory WeeklyHistoryItem.fromJson(Map<String, dynamic> json) {
    return WeeklyHistoryItem(
      weekStartDate: json['week_start_date'] != null 
          ? DateTime.parse(json['week_start_date'] as String) 
          : DateTime.now(),
      targetDays: json['target_days'] as int? ?? 0,
      completedDays: json['completed_days'] as int? ?? 0,
      successPercentage: (json['success_percentage'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'week_start_date': weekStartDate.toIso8601String(),
      'target_days': targetDays,
      'completed_days': completedDays,
      'success_percentage': successPercentage,
    };
  }
}
