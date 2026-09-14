import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF00E5A0); // Neon yeşil-turkuaz accent
  static const Color primaryDark = Color(0xFF00B380); // Gradient/pressed durum

  // Theme Colors (Premium Dark)
  static const Color background = Color(0xFF0D0F12); // Soğuk antrasit zemin
  static const Color surface = Color(0xFF16191E); // Panel/yüzey zemini
  static const Color card = Color(0xFF1E2228); // Yükseltilmiş kart zemini

  // Text Colors
  static const Color textPrimary = Color(0xFFF2F4F7); // Birincil metin
  static const Color textSecondary = Color(0xFF9BA1AC); // İkincil metin
  static const Color textMuted = Color(0xFF5A616B); // Pasif metin

  // Functional Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E); // Başarı
  static const Color warning = Color(0xFFFBBF24); // Uyarı
  static const Color info = Color(0xFF38BDF8); // Bilgi durumu + su modülü

  // Chat Colors
  static const Color chatBubbleMine = Color(0x2600E5A0);
  static const Color chatBubbleMineBorder = Color(0x4D00E5A0);
  static const Color chatBubbleTheirs = card;
  static const Color unreadIndicator = primary;

  // Macro & Nutrient Colors
  static const Color protein = Color(0xFFF97316); // Orange
  static const Color carbs = Color(0xFFFACC15);   // Yellow
  // Menekşe. Eskiden emerald (#10B981) idi ve accent yeşiline (#00E5A0) o kadar
  // yakındı ki makro barının yağ dilimi accent gibi okunuyordu. Makro üçlüsü birlikte
  // gösterildiği için ayırt edilebilirlik burada estetik değil okunabilirlik meselesi:
  // turuncu (protein) ve sarı (karbonhidrat) yanında üçüncü ton soğuk olmalı.
  static const Color fat = Color(0xFFA78BFA);     // Violet
  static const Color sugar = Color(0xFFEF4444);   // Red
  static const Color fiber = Color(0xFF22C55E);   // Green
  static const Color sodium = Color(0xFF3B82F6);  // Blue
  static const Color cholesterol = Color(0xFFF97316); // Orange-Accent
  static const Color potassium = Color(0xFFA855F7);  // Purple

  // Glassmorphism Helpers
  static const Color glassWhite = Color(0x14FFFFFF); // ~8% Opacity
  static const Color glassBorder = Color(0x1FFFFFFF); // ~12% Opacity

  // Kas grubu paleti — KATEGORİK VERİ rengi, dekoratif değil.
  // Renk burada bilginin kendisidir: çipe bakan kişi hangi bölge olduğunu
  // okumadan ayırt edebilmeli. Bu yüzden §3.1'in "tek accent" kuralı burada
  // GEÇERLİ DEĞİL — makro (protein/carbs/fat) ve ölçüm grafiği paletiyle aynı sınıf.
  //
  // Hue'lar çember üzerinde ~33° aralıkla dağıtıldı; doygunluk ve açıklık
  // koyu zeminde okunacak şekilde eşitlendi. FULL_BODY bilinçli olarak nötr:
  // belirli bir bölge değil, "hepsi" demek.
  static const Color muscleChest = Color(0xFFFF8A3D); // turuncu
  static const Color muscleBack = Color(0xFF3D9BFF); // mavi
  static const Color muscleShoulders = Color(0xFF22D3EE); // camgöbeği
  static const Color muscleBiceps = Color(0xFF818CF8); // indigo
  static const Color muscleTriceps = Color(0xFFF87171); // mercan
  static const Color muscleQuadriceps = Color(0xFFC084FC); // mor
  static const Color muscleHamstrings = Color(0xFFF472B6); // pembe
  static const Color muscleCalves = Color(0xFFB8E62E); // limon yeşili
  static const Color muscleAbs = Color(0xFF4ADE80); // yeşil
  static const Color muscleCardio = Color(0xFFFFC53D); // amber
  static const Color muscleFullBody = Color(0xFF94A3B8); // nötr gri

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [
      Color(0x1F00E5A0), // primary ~12%
      Color(0x0D00B380), // primaryDark ~5%
      Colors.transparent,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [
      card,
      surface,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Compatibility (Will be removed after global redesign)
  static const Color textDark = textPrimary;
  static const Color textSlate = textSecondary;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color white = Colors.white;
  static const List<BoxShadow> neoShadow = [
    BoxShadow(color: primary, blurRadius: 20, offset: Offset(0, 10)),
  ];

  // Measurement Chart Series Colors
  static const List<Color> measurementChart = [
    Color(0xFF3B82F6), // Canlı mavi
    Color(0xFFEC4899), // Pembe
    Color(0xFF10B981), // Zümrüt yeşili
    Color(0xFFF59E0B), // Amber/Turuncu
    Color(0xFF8B5CF6), // Mor
    Color(0xFFEF4444), // Kırmızı
    Color(0xFF06B6D4), // Turkuaz/Cyan
    Color(0xFF84CC16), // Fıstık yeşili
    Color(0xFF6366F1), // Çivit mavisi
    Color(0xFF14B8A6), // Teal
  ];

  // Analiz öğün-tipi lejant paleti
  static const Color mealBreakfast = Color(0xFFFF719A);
  static const Color mealLunch = Color(0xFFFACD15);
  static const Color mealDinner = Color(0xFF6366F1);
  static const Color mealPreWorkout = Color(0xFF4ADE80);
  static const Color mealPostWorkout = Color(0xFFF472B6);
  static const Color mealOther = Color(0xFF94A3B8);
}
