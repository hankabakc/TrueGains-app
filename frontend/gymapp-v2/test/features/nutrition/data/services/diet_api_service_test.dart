import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:gymapp_v2/features/nutrition/data/services/diet_api_service.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);
}

void main() {
  test('DietApiService togglePlannedMeal formats query parameters correctly', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    
    RequestOptions? capturedRequest;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        capturedRequest = options;
        handler.resolve(Response(
          requestOptions: options,
          data: {'success': true, 'message': 'Success', 'data': {'id': 1}},
          statusCode: 200,
        ));
      },
    ));

    final apiService = DietApiService(FakeDioClient(dio));

    await apiService.togglePlannedMeal(
      '2026-06-02',
      123,
      true,
      ingredientIds: [456, 789],
    );

    expect(capturedRequest, isNotNull);
    
    final uri = capturedRequest!.uri;
    final queryStr = uri.query;
    // ignore: avoid_print
    print('Generated Request Query String: $queryStr');
    
    expect(queryStr.contains('ingredientIds=456'), isTrue);
    expect(queryStr.contains('ingredientIds=789'), isTrue);
    expect(queryStr.contains('ingredientIds%5B%5D'), isFalse);
  });
}
