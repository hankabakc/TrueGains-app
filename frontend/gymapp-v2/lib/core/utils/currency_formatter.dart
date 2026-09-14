abstract final class CurrencyFormatter {
  static String format(double? value, String? currency) {
    if (value == null) return '';
    // Değer tam sayıysa ondalığı gösterme, değilse tek ondalık göster.
    final String formatted = value == value.toInt() ? value.toInt().toString() : value.toStringAsFixed(1);
    final String unit = currency ?? '₺';
    return '$formatted $unit';
  }
}
