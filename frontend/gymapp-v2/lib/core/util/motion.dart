import 'package:flutter/material.dart';

/// Cihazın "animasyonları kaldır" erişilebilirlik ayarı açıkken süreyi sıfırlar.
/// Intro akışındaki her geçiş bu fonksiyondan geçer.
Duration motionDuration(BuildContext context, Duration d) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
}
