import 'package:flutter/foundation.dart';

/// Ekrandaki verinin önbellekten mi geldiğini taşır.
///
/// Değer `null` ise veri taze; doluysa önbellekten gelmiştir ve tarih o kaydın
/// **yazıldığı** andır. Ağ katmanı yazar, arayüz dinler — araya bloc konmadı,
/// çünkü bilgi tek ve global.
class CacheStatusNotifier extends ValueNotifier<DateTime?> {
  CacheStatusNotifier() : super(null);

  void markStale(DateTime? cachedAt) => value = cachedAt ?? DateTime.now();

  void markFresh() {
    if (value != null) value = null;
  }
}
