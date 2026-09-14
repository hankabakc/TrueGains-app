import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/constants/storage_keys.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/auth/data/repositories/auth_repository.dart';
import 'package:gymapp_v2/features/auth/data/services/auth_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late MockSecureStorage mockSecureStorage;
  late AuthApiService authApiService;
  late AuthRepository authRepository;

  setUpAll(() {
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

    when(() => mockDioClient.dio).thenReturn(mockDio);
    when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    authApiService = AuthApiService(mockDioClient, mockSecureStorage);
    authRepository = AuthRepository(authApiService);
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
}
