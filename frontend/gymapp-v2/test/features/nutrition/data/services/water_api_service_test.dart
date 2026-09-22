import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/nutrition/data/services/water_api_service.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// G-86: su kaydı sunucuda zaten silinmişse silme başarılıdır; başka ret başarı sayılmaz.
void main() {
  Dio rejectingDio(int status, String message) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: status,
            data: <String, dynamic>{'success': false, 'message': message},
          ),
        ));
      },
    ));
    return dio;
  }

  test('silinecek su kaydı sunucuda yoksa (404) silme başarılı sayılır', () async {
    final result = await WaterApiService(FakeDioClient(rejectingDio(404, 'Su kaydı bulunamadı: 9'))).deleteWaterIntake(9);

    expect(result.success, isTrue);
  });

  test('başkasının su kaydını silme (400) başarı sayılmaz', () async {
    final result = await WaterApiService(FakeDioClient(rejectingDio(400, 'Bu kayıt size ait değil.'))).deleteWaterIntake(9);

    expect(result.success, isFalse);
    expect(result.message, 'Bu kayıt size ait değil.');
  });
}
