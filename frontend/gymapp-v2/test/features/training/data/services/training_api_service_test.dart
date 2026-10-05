import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/training/data/services/training_api_service.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
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

  test('getAllExercises on 409 returns server message when present', () async {
    final dio = rejectingDio(409, <String, dynamic>{
      'success': false,
      'message': 'Bu antrenörü zaten değerlendirdiniz.',
    });
    final service = TrainingApiService(FakeDioClient(dio));

    final response = await service.getAllExercises();

    expect(response.success, isFalse);
    expect(response.message, 'Bu antrenörü zaten değerlendirdiniz.');
  });

  test('getAllExercises on 409 returns fallback conflict text when data is null', () async {
    final dio = rejectingDio(409, null);
    final service = TrainingApiService(FakeDioClient(dio));

    final response = await service.getAllExercises();

    expect(response.success, isFalse);
    expect(
      response.message,
      'Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.',
    );
  });
}
