import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/auth/data/services/auth_api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Dio rejectingDio(int statusCode, Object? data) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
        ));
      },
    ));
    return dio;
  }

  test('login on 409 returns server message when present', () async {
    final dio = rejectingDio(409, <String, dynamic>{
      'success': false,
      'message': 'Bu antrenörü zaten değerlendirdiniz.',
    });
    final service = AuthApiService(FakeDioClient(dio), MockSecureStorage());

    final response = await service.login('a@b.c', 'x');

    expect(response.success, isFalse);
    expect(response.message, 'Bu antrenörü zaten değerlendirdiniz.');
  });

  test('login on 409 returns fallback conflict text when data is null', () async {
    final dio = rejectingDio(409, null);
    final service = AuthApiService(FakeDioClient(dio), MockSecureStorage());

    final response = await service.login('a@b.c', 'x');

    expect(response.success, isFalse);
    expect(
      response.message,
      'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.',
    );
  });
}
