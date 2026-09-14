import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/config/app_config.dart';

/// Ek adreslerinin çözümü.
///
/// Sunucu ekleri yalnızca yol olarak saklıyor; sunucu adını istemci ekliyor. Çözüm
/// bozulursa görseller ya hiç yüklenmez ya da — daha kötüsü — eski kayıtlardaki mutlak
/// adres bozularak yanlış yere istek atılır.
void main() {
  test('göreli yol kendi sunucumuzun adresine tamamlanıyor', () {
    final String origin = Uri.parse(AppConfig.apiBaseUrl).origin;

    expect(
      AppConfig.resolveFileUrl('/api/v1/files/abc.jpg'),
      '$origin/api/v1/files/abc.jpg',
    );
  });

  test('eski mutlak dosya adresi bugünkü sunucuya taşınır', () {
    // Adres, dosyanın yüklendiği günkü makinenin IP'siyle kaydedilmiş olabilir.
    // 192.0.2.x belgeleme için ayrılmış adres bloğu (RFC 5737), gerçek bir makine değil.
    final String origin = Uri.parse(AppConfig.apiBaseUrl).origin;
    expect(
      AppConfig.resolveFileUrl('http://192.0.2.10:8082/api/v1/files/abc.jpg'),
      '$origin/api/v1/files/abc.jpg',
    );
  });

  test('yabancı sunucudaki adres olduğu gibi kalır', () {
    expect(
      AppConfig.resolveFileUrl('https://i.pravatar.cc/300?u=sporcu@test.com'),
      'https://i.pravatar.cc/300?u=sporcu@test.com',
    );
  });

  test('dosya yolu dışındaki mutlak adres yeniden yazılmaz', () {
    expect(
      AppConfig.resolveFileUrl('https://sunucu/baska/yol.png'),
      'https://sunucu/baska/yol.png',
    );
  });

  test('tamamlanan adres tek bir eğik çizgiyle birleşiyor', () {
    // Origin sonunda eğik çizgi taşımaz; yol başında taşır. İkisi birleşince
    // "//api/v1" oluşursa istek 404 döner.
    expect(AppConfig.resolveFileUrl('/api/v1/files/x.jpg'), isNot(contains('//api/v1')));
  });

  test('varsayılan API adresi emülatörden host makineye çıkar', () {
    // Sabit yerel IP'ye dönülürse makinenin IP'si değiştiği anda giriş zaman aşımına düşer.
    expect(AppConfig.apiBaseUrl, 'http://10.0.2.2:8082/api/v1');
  });

  test('WebSocket adresi API ile aynı sunucuyu gösterir', () {
    final Uri api = Uri.parse(AppConfig.apiBaseUrl);
    final Uri ws = Uri.parse(AppConfig.wsUrl);
    expect(ws.authority, api.authority);
    expect(ws.scheme, 'ws');
    expect(ws.path, '/ws-raw');
  });
}
