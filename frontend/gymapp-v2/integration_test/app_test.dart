import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gymapp_v2/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// GYMAPP-V2 uçtan uca (E2E) testleri.
///
/// ÖN KOŞUL ZİNCİRİ (bu testler ancak bunlar sağlandığında anlamlıdır):
///   1. `docker compose up -d`  → PostgreSQL ayakta
///   2. `mvn spring-boot:run`   → backend VARSAYILAN profille ayakta
///   3. `backend/gym-v2/seed_users.ps1` → tohum veri yüklü
///
/// Çalıştırma (Android emülatörü, backend host makinede):
///   flutter test integration_test/app_test.dart -d emulator-5554 \
///     --dart-define=API_BASE_URL=http://10.0.2.2:8082/api/v1
///
/// Bu testler gerçek backend'e karşı koşar; ağ yoksa BAŞARISIZ olurlar.
/// Bu bilinçlidir: sessizce geçen bir E2E testi, hiç olmamasından daha kötüdür.
///
/// NEDEN TEK `testWidgets`? `app.main()` süreç başına yalnızca bir kez çağrılabilir;
/// `initDependencies` GetIt'e kayıt yaptığı için ikinci çağrı
/// "Type SharedPreferences is already registered" hatası verir.
///
/// NEDEN `pumpAndSettle` YOK? Panel ekranında süreklilik arz eden animasyonlar var;
/// `pumpAndSettle` "kare kalmayana kadar" beklediği için bu ekranda asla dönmez ve
/// varsayılan 10 dakikalık timeout'a takılır. Bunun yerine aşağıdaki `bekle` yardımcısı
/// sabit adımlarla pump eder ve aradığı widget görünür görünmez durur.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Test hesabı komut satırından verilir; hesap bilgisi kaynakta tutulmaz. Akış 2 ve 3
  // atanmış diyet/antrenman programı gerektirir, bu yüzden veri taşıyan bir hesap seçilmeli:
  //   --dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...
  const String seededEmail = String.fromEnvironment('E2E_EMAIL');
  const String seededPassword = String.fromEnvironment('E2E_PASSWORD');
  if (seededEmail.isEmpty || seededPassword.isEmpty) {
    throw StateError(
      'E2E_EMAIL ve E2E_PASSWORD --dart-define ile verilmeli; kaynakta varsayılan hesap yok.',
    );
  }

  /// [finder] görünene kadar sınırlı sayıda kare ilerletir. Süre dolarsa `false` döner;
  /// asla süresiz beklemez.
  Future<bool> bekle(
    WidgetTester tester,
    Finder finder, {
    Duration limit = const Duration(seconds: 20),
  }) async {
    final int adim = limit.inMilliseconds ~/ 250;
    for (int i = 0; i < adim; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  /// Panel uzun ve tembel (lazy) bir liste; aranan widget ilk karede ağaçta olmayabilir.
  /// Bulunana kadar aşağı kaydırır. Kullanıcı verisini değiştiren hiçbir butona dokunmaz.
  Future<bool> kaydirVeBul(WidgetTester tester, Finder finder,
      {int adim = 12}) async {
    if (finder.evaluate().isNotEmpty) return true;
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return false;
    for (int i = 0; i < adim; i++) {
      await tester.drag(scrollable.first, const Offset(0, -350));
      await tester.pump(const Duration(milliseconds: 300));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  testWidgets('E2E: giriş → panel → kalori özeti → antrenman ekranı',
      (WidgetTester tester) async {
    // ---------------------------------------------------------------
    // HAZIRLIK — "dönen kullanıcı" durumu
    // Temiz kurulumda uygulama 12 adımlı intro anketiyle açılır. Bu testin konusu
    // intro değil, giriş sonrası akışlar; bu yüzden intro görülmüş olarak işaretlenir.
    // Anahtar adı üretimdeki `LastRouteStore._kIntroSeen` ile aynıdır.
    // ---------------------------------------------------------------
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);

    // ---------------------------------------------------------------
    // AKIŞ 1 — Tohum hesapla giriş yapılır ve ana panele ulaşılır
    // ---------------------------------------------------------------
    app.main();
    await tester.pump(const Duration(seconds: 1));

    final panel = find.text('Panel');

    // Önceki koşudan oturum kalmış olabilir; kalmadıysa giriş yap.
    if (!await bekle(tester, panel, limit: const Duration(seconds: 8))) {
      final girisLinki = find.text('Giriş Yap');
      if (girisLinki.evaluate().isNotEmpty) {
        await tester.tap(girisLinki.first);
        await bekle(tester, find.byType(TextField), limit: const Duration(seconds: 8));
      }

      final alanlar = find.byType(TextField);
      expect(alanlar, findsAtLeastNWidgets(2),
          reason: 'Giriş ekranında e-posta ve şifre alanları bulunamadı');

      await tester.enterText(alanlar.at(0), seededEmail);
      await tester.enterText(alanlar.at(1), seededPassword);
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Başlayalım'));

      // Gerçek ağ çağrısı + yönlendirme: panelin gelmesini bekle.
      final girisBasarili = await bekle(tester, panel, limit: const Duration(seconds: 30));
      expect(girisBasarili, isTrue,
          reason: 'Giriş sonrası ana panel açılmadı — kimlik doğrulama akışı kırık olabilir');
    }

    expect(panel, findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // ---------------------------------------------------------------
    // AKIŞ 3 (önce ölçülür) — Panelde günlük kalori özeti gösterilir
    // ---------------------------------------------------------------
    // Kalori özeti panelin alt kısmında; tembel liste yüzünden kaydırmak gerekir.
    final kaloriOzeti = await kaydirVeBul(tester, find.text('kcal'));
    expect(kaloriOzeti, isTrue, reason: 'Panelde günlük kalori özeti bulunamadı');

    // ---------------------------------------------------------------
    // AKIŞ 2 — Panelden antrenman ekranına geçilir
    // ---------------------------------------------------------------
    // Panel, günün tipine göre iki farklı etiket gösteriyor: normal antrenman gününde
    // "İDMANI İNCELE VE BAŞLA", dinlenme gününde "GÜNÜ İNCELE VE BAŞLA". İkisi de aynı
    // ekrana götürür; test hangi gün koşulduğuna bağlı olmamalı.
    final antrenmanGirisi = find.byWidgetPredicate((w) =>
        w is Text &&
        (w.data == 'İDMANI İNCELE VE BAŞLA' || w.data == 'GÜNÜ İNCELE VE BAŞLA'));
    final antrenmanVar = await kaydirVeBul(tester, antrenmanGirisi);
    expect(antrenmanVar, isTrue,
        reason: 'Panelde antrenman giriş noktası yok — atanmış program bulunamadı');
    await tester.ensureVisible(antrenmanGirisi.first);

    await tester.tap(antrenmanGirisi.first);

    // Antrenman ekranına geçildiyse egzersiz listesi başlığı görünür.
    // Antrenman özeti ekranı açıldığında başlatma butonu ve programın egzersiz
    // bilgisi render edilir. Bu iki işaret, ekranın gerçek veriyle dolduğunu kanıtlar.
    final antrenmanEkrani = await bekle(tester, find.text('İDMANI BAŞLAT'));
    expect(antrenmanEkrani, isTrue,
        reason: 'Antrenman ekranı açılmadı — başlatma butonu görünmedi');
    expect(find.textContaining('Set'), findsAtLeastNWidgets(1),
        reason: 'Antrenman ekranı açıldı ama egzersiz/set bilgisi gelmedi');
  });
}
