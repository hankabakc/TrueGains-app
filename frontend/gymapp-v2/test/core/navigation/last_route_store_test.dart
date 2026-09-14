import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/navigation/last_route_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LastRouteStore readTabIndex', () {
    test('kayıt yokken 0 döner', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LastRouteStore(prefs);
      expect(store.readTabIndex(), 0);
    });

    test('indeks 4 (Profil) korunur', () async {
      SharedPreferences.setMockInitialValues({'last_tab_index': 4});
      final prefs = await SharedPreferences.getInstance();
      final store = LastRouteStore(prefs);
      expect(store.readTabIndex(), 4);
    });

    test("sınır dışı indeks 0'a düşer", () async {
      SharedPreferences.setMockInitialValues({'last_tab_index': 5});
      final prefs = await SharedPreferences.getInstance();
      final store = LastRouteStore(prefs);
      expect(store.readTabIndex(), 0);
    });

    test("negatif indeks 0'a düşer", () async {
      SharedPreferences.setMockInitialValues({'last_tab_index': -1});
      final prefs = await SharedPreferences.getInstance();
      final store = LastRouteStore(prefs);
      expect(store.readTabIndex(), 0);
    });
  });
}
