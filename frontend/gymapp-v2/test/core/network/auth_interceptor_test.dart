import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/constants/network_constants.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/network/auth_interceptor.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Yol başına sıralı cevap verir; `null` o istekte sunucuya ulaşılamadığı demektir.
/// Her isteğin yolunu ve giden `Authorization` başlığını kaydeder.
class _ScriptedAdapter implements HttpClientAdapter {
  final Map<String, List<(int, Map<String, dynamic>)?>> replies = <String, List<(int, Map<String, dynamic>)?>>{};
  final List<(String, String?)> calls = <(String, String?)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add((options.path, options.headers[NetworkConstants.authorizationHeader] as String?));
    final (int, Map<String, dynamic>)? reply = replies[options.path]!.removeAt(0);
    if (reply == null) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    }
    return ResponseBody.fromString(
      jsonEncode(reply.$2),
      reply.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Oturum yenileme (G-82, K4-11). Etki kontrol edilir (KURALLAR §4/9): saklanan jeton depodan okunur,
/// çıkış `AuthBloc.add` ile doğrulanır, tekrarlanan isteğin giden başlığı adaptörden okunur.
void main() {
  const String refreshPath = '/auth/refresh';
  const Timeout hangGuard = Timeout(Duration(seconds: 5));
  final Map<String, dynamic> refreshOk = <String, dynamic>{
    'success': true,
    'data': <String, dynamic>{
      'access_token': 'yeni',
      'token_type': 'Bearer',
      'expires_in': 86400,
      'user': <String, dynamic>{'id': 7, 'email': 'sporcu@test.com', 'role': 'CLIENT'},
    },
  };

  late _ScriptedAdapter adapter;
  late Dio dio;
  late MockAuthBloc authBloc;

  Future<String?> storedToken() => const FlutterSecureStorage().read(key: StorageKeys.accessToken);

  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      StorageKeys.accessToken: 'eski',
      'device_id': 'cihaz-1',
    });
    authBloc = MockAuthBloc();
    sl.registerSingleton<AuthBloc>(authBloc);
    adapter = _ScriptedAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(dio));
  });

  tearDown(() async {
    await sl.reset();
  });

  test('erişim jetonu dolunca yeni jeton saklanır ve istek yeni jetonla tekrarlanır', () async {
    adapter.replies['/profile'] = [
      (401, <String, dynamic>{'message': 'Yetkisiz'}),
      (200, <String, dynamic>{'success': true, 'data': 'veri'}),
    ];
    adapter.replies[refreshPath] = [(200, refreshOk)];

    final res = await dio.get<Map<String, dynamic>>('/profile');

    expect(res.data!['data'], 'veri');
    expect(await storedToken(), 'yeni');
    expect(adapter.calls.last, ('/profile', 'Bearer yeni'));
    verifyNever(() => authBloc.add(any()));
  }, timeout: hangGuard);

  test('yenileme cevabında jeton yoksa kilit açılır, sonraki 401 kendi yenilemesini yapar', () async {
    adapter.replies['/profile'] = [
      (401, <String, dynamic>{}),
      (401, <String, dynamic>{}),
    ];
    adapter.replies[refreshPath] = [
      (200, <String, dynamic>{'success': true, 'data': <String, dynamic>{}}),
      (200, <String, dynamic>{'success': true, 'data': <String, dynamic>{}}),
    ];

    await expectLater(dio.get<Map<String, dynamic>>('/profile'), throwsA(isA<DioException>()));
    await expectLater(dio.get<Map<String, dynamic>>('/profile'), throwsA(isA<DioException>()));

    expect(adapter.calls.where(((String, String?) c) => c.$1 == refreshPath).length, 2);
    verifyNever(() => authBloc.add(any()));
  }, timeout: hangGuard);

  test('yenilenen jetonla tekrarlanan istek reddedilirse oturum kapanmaz, çağırana gerçek hata gider', () async {
    adapter.replies['/training/sessions'] = [
      (401, <String, dynamic>{}),
      (409, <String, dynamic>{'message': 'Çakışma'}),
    ];
    adapter.replies[refreshPath] = [(200, refreshOk)];

    await expectLater(
      dio.post<Map<String, dynamic>>('/training/sessions', data: <String, dynamic>{'localId': 'a'}),
      throwsA(isA<DioException>().having((DioException e) => e.response?.statusCode, 'statusCode', 409)),
    );

    expect(await storedToken(), 'yeni');
    verifyNever(() => authBloc.add(any()));
  }, timeout: hangGuard);

  test('yenileme sunucuya ulaşamazsa jeton silinmez ve çıkış yapılmaz', () async {
    adapter.replies['/profile'] = [
      (401, <String, dynamic>{}),
    ];
    adapter.replies[refreshPath] = [null];

    await expectLater(
      dio.get<Map<String, dynamic>>('/profile'),
      throwsA(isA<DioException>().having((DioException e) => e.response?.statusCode, 'statusCode', 401)),
    );

    expect(await storedToken(), 'eski');
    verifyNever(() => authBloc.add(any()));
  }, timeout: hangGuard);

  test('sunucu yenilemeyi reddederse jeton silinir ve çıkış tetiklenir', () async {
    adapter.replies['/profile'] = [
      (401, <String, dynamic>{}),
    ];
    adapter.replies[refreshPath] = [
      (401, <String, dynamic>{'message': 'Refresh Token süresi dolmuş.'}),
    ];

    await expectLater(dio.get<Map<String, dynamic>>('/profile'), throwsA(isA<DioException>()));

    expect(await storedToken(), isNull);
    verify(() => authBloc.add(const LogoutRequested(syncPending: false))).called(1);
  }, timeout: hangGuard);

  test('yenileme isteğine erişim jetonu eklenmez, diğer isteklere eklenir', () async {
    adapter.replies['/profile'] = [
      (401, <String, dynamic>{'message': 'Yetkisiz'}),
      (200, <String, dynamic>{'success': true, 'data': 'veri'}),
    ];
    adapter.replies[refreshPath] = [(200, refreshOk)];

    await dio.get<Map<String, dynamic>>('/profile');

    expect(
      adapter.calls.where(((String, String?) c) => c.$1 == refreshPath).map(((String, String?) c) => c.$2).toList(),
      equals(<String?>[null]),
    );
    expect(adapter.calls.first, ('/profile', 'Bearer eski'));
  }, timeout: hangGuard);
}

