import 'dart:async';
import 'package:flutter/material.dart';

/// Bir Stream'i (örn: BLoC stream) dinleyerek GoRouter'a haber veren yardımcı sınıf.
/// [GÖREV 1.3]: Bellek sızıntısını önlemek için dispose mekanizması içerir.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
