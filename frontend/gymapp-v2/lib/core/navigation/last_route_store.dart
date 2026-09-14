import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LastRouteStore {
  final SharedPreferences _prefs;

  LastRouteStore(this._prefs);

  static const String _kLocation = 'last_location';
  static const String _kTabIndex = 'last_tab_index';
  static const String _kIntroSeen = 'intro_seen';
  static const List<String> _blockedPrefixes = [
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/onboarding',
    '/verify-otp',
    '/checkout',
    '/nutrition/scan',
    '/nutrition/gemini-analysis',
    '/active-workout',
    '/workout-summary',
    '/intro',
  ];

  void attach(GoRouter router) {
    router.routerDelegate.addListener(() {
      final RouteMatchList config = router.routerDelegate.currentConfiguration;
      if (config.isEmpty) return;
      _save(config.uri.toString(), config.extra != null);
    });
  }

  void _save(String location, bool hasExtra) {
    if (location == '/main') {
      _prefs.setString(_kLocation, '/main');
      return;
    }
    if (hasExtra) return;
    for (final prefix in _blockedPrefixes) {
      if (location == prefix || location.startsWith('$prefix/')) return;
    }
    _prefs.setString(_kLocation, location);
  }

  String readLocation() {
    return _prefs.getString(_kLocation) ?? '/main';
  }

  bool readIntroSeen() {
    return _prefs.getBool(_kIntroSeen) ?? false;
  }

  void markIntroSeen() {
    _prefs.setBool(_kIntroSeen, true);
  }

  void saveTabIndex(int index) {
    _prefs.setInt(_kTabIndex, index);
  }

  int readTabIndex() {
    final val = _prefs.getInt(_kTabIndex);
    if (val == null || val < 0 || val > 4) return 0;
    return val;
  }

  void clear() {
    _prefs.remove(_kLocation);
    _prefs.remove(_kTabIndex);
  }
}
