import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/util/age_calculator.dart';

/// Yaş hesabı.
///
/// Buradaki en pahalı hata "yanlış yaş" değil, **uydurma yaş**: bilinmeyen tarih için
/// sayı üretilirse koç sporcunun yaşını 0 görür ve bunun bir hata olduğunu anlayamaz.
void main() {
  final DateTime now = DateTime(2026, 8, 16);

  group('bilinmeyen tarih', () {
    test('tarih yoksa null döner', () {
      expect(calculateAge(null, now: now), isNull);
    });

    test('tarih okunamıyorsa null döner — 0 değil', () {
      expect(calculateAge('bozuk-tarih', now: now), isNull);
      expect(calculateAge('', now: now), isNull);
    });
  });

  group('doğum günü sınırı', () {
    test('doğum günü geçtiyse tam yaş', () {
      expect(calculateAge('2000-08-15', now: now), 26);
    });

    test('doğum günü bugünse tam yaş', () {
      expect(calculateAge('2000-08-16', now: now), 26);
    });

    test('doğum günü yarınsa bir eksik', () {
      expect(calculateAge('2000-08-17', now: now), 25);
    });

    test('doğum ayı ilerideyse bir eksik', () {
      expect(calculateAge('2000-12-01', now: now), 25);
    });

    test('doğum ayı geçmişse tam yaş', () {
      expect(calculateAge('2000-01-01', now: now), 26);
    });
  });

  test('tam ISO zaman damgası da kabul edilir', () {
    // Profil ekranı DateTime.toIso8601String() ile saat bilgisini de gönderiyor.
    expect(calculateAge('2000-01-01T00:00:00.000', now: now), 26);
  });
}
