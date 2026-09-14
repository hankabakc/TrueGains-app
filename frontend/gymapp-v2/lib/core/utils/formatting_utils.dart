class FormattingUtils {
  /// 00:00 formatında süre döndürür.
  static String formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Sayıyı okunabilir porsiyon formatına çevirir (Örn: 1.0 -> 1, 1.5 -> 1.5).
  static String formatAmount(double amount) {
    return amount.toStringAsFixed(1).replaceFirst('.0', '');
  }
}
