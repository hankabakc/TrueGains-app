/// Koç Paneli İstatistik Modeli.
class CoachDashboardStats {
  final int activeStudents;
  final double monthlyEarnings;

  const CoachDashboardStats({
    required this.activeStudents,
    required this.monthlyEarnings,
  });

  factory CoachDashboardStats.fromJson(Map<String, dynamic> json) {
    return CoachDashboardStats(
      activeStudents: (json['activeStudents'] as num?)?.toInt() ?? 0,
      monthlyEarnings: (json['monthlyEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
