import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/constants/network_constants.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/data/services/auth_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockCookieJar extends Mock implements PersistCookieJar {}
class MockSyncManager extends Mock implements SyncManager {}
class MockOfflineCache extends Mock implements OfflineCache {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;
  late MockCookieJar mockCookieJar;
  late MockSyncManager mockSyncManager;
  late MockOfflineCache mockOfflineCache;
  late AuthApiService authApiService;
  late AuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(Options());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'mock_device_id_123';
        }
        if (methodCall.method == 'write') {
          return null;
        }
        return null;
      },
    );
  });

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();
    mockSecureStorage = MockSecureStorage();
    mockCookieJar = MockCookieJar();
    mockSyncManager = MockSyncManager();
    mockOfflineCache = MockOfflineCache();

    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockDioClient.cookieJar).thenReturn(mockCookieJar);
    when(() => mockCookieJar.deleteAll()).thenAnswer((_) async {});
    when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    when(() => mockSyncManager.syncPendingData()).thenAnswer((_) async {});
    when(() => mockOfflineCache.clear()).thenAnswer((_) async {});
    when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    authApiService = AuthApiService(mockDioClient, mockSecureStorage);
    authRepository = AuthRepository(authApiService, mockSyncManager, mockOfflineCache);
  });

  test('kayıt isteği payloadı → /auth/register ucuna beklenen JSON verisini gönderir', () async {
    final requestData = <String, dynamic>{
      'email': 'newuser@example.com',
      'password': 'Password123!',
      'role': 'CLIENT',
      'phoneNumber': '+905555555555',
    };

    when(() => mockDio.post<Map<String, dynamic>>(
          '/auth/register',
          data: requestData,
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 200,
          data: {'success': true, 'message': 'Kayıt başarılı'},
        ));

    final result = await authRepository.register(requestData);

    expect(result.success, isTrue);
    verify(() => mockDio.post<Map<String, dynamic>>(
          '/auth/register',
          data: requestData,
        )).called(1);
  });

  test('başarılı girişte → gelen erişim tokenı FlutterSecureStorage üzerine kaydedilir', () async {
    final responsePayload = <String, dynamic>{
      'success': true,
      'data': {
        'access_token': 'mock_access_token_123',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'user': {
          'id': 1,
          'email': 'test@example.com',
          'role': 'CLIENT',
        },
      },
    };

    when(() => mockDio.post<Map<String, dynamic>>(
          '/auth/login',
          data: any(named: 'data'),
        )).thenAnswer((_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 200,
          data: responsePayload,
        ));

    final result = await authRepository.login('test@example.com', 'Password123!');

    expect(result.success, isTrue);
    expect(result.data?.accessToken, equals('mock_access_token_123'));
    verify(() => mockSecureStorage.write(
          key: StorageKeys.accessToken,
          value: 'mock_access_token_123',
        )).called(1);
  });

  test('401 HTTP ağ hatasında → anlaşılır bir istisna/yanıt mesajı döner', () async {
    when(() => mockDio.post<Map<String, dynamic>>(
          '/auth/login',
          data: any(named: 'data'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
        data: {'message': 'Geçersiz e-posta veya şifre'},
      ),
      type: DioExceptionType.badResponse,
    ));

    final result = await authRepository.login('test@example.com', 'wrongpass');

    expect(result.success, isFalse);
    expect(result.statusCode, equals(401));
    expect(result.message, equals('Geçersiz e-posta veya şifre'));
  });

  group('çıkış', () {
    setUp(() {
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => 'tok');
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/logout',
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/logout'),
            statusCode: 200,
            data: {'success': true},
          ));
    });

    test('çıkış: kuyruk gönderilir, jeton ve çerez silinir, sunucuya bildirilir, önbellek temizlenir — bu sırayla', () async {
      await authRepository.logout();

      verifyInOrder([
        () => mockSyncManager.syncPendingData(),
        () => mockSecureStorage.delete(key: StorageKeys.accessToken),
        () => mockCookieJar.deleteAll(),
        () => mockDio.post<Map<String, dynamic>>(
              '/auth/logout',
              options: any(named: 'options'),
            ),
        () => mockOfflineCache.clear(),
      ]);
    });

    test('çıkış: sunucu çağrısı okunan jetonu Authorization başlığında taşır', () async {
      await authRepository.logout();

      final captured = (verify(() => mockDio.post<Map<String, dynamic>>(
            '/auth/logout',
            options: captureAny(named: 'options'),
          )).captured.single as Options);

      expect(
        captured.headers![NetworkConstants.authorizationHeader],
        equals('${NetworkConstants.bearerPrefix}tok'),
      );
    });

    test('çıkış: jeton yoksa sunucuya gidilmez, yerel temizlik yine yapılır', () async {
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => null);

      await authRepository.logout();

      verifyNever(() => mockDio.post<Map<String, dynamic>>(
            any(),
            options: any(named: 'options'),
          ));
      verify(() => mockSecureStorage.delete(key: StorageKeys.accessToken)).called(1);
      verify(() => mockCookieJar.deleteAll()).called(1);
      verify(() => mockOfflineCache.clear()).called(1);
    });

    test('çıkış: sunucuya ulaşılamasa da hata fırlatmaz, jeton ve çerez silinmiş olur', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            '/auth/logout',
            options: any(named: 'options'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/auth/logout'),
        type: DioExceptionType.connectionError,
      ));

      await expectLater(authRepository.logout(), completes);

      verify(() => mockSecureStorage.delete(key: StorageKeys.accessToken)).called(1);
      verify(() => mockCookieJar.deleteAll()).called(1);
      verify(() => mockOfflineCache.clear()).called(1);
    });

    test('oturum düşünce çıkış kuyruğu göndermeye çalışmaz', () async {
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => null);

      await authRepository.logout(syncPending: false);

      verifyNever(() => mockSyncManager.syncPendingData());
      verify(() => mockOfflineCache.clear()).called(1);
    });
  });
}
