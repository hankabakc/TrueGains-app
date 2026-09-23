import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/features/nutrition/data/models/food_model.dart';
import 'package:gymapp_v2/features/nutrition/data/services/food_api_service.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Özel besin oluşturma (G-87): cihaz kimliği istek gövdesinde gider; sunucu aynı kimlikle ikinci besin açmaz.
void main() {
  test('özel besin cihaz kimliğiyle birlikte gönderilir', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    RequestOptions? sent;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        sent = options;
        handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'success': true, 'message': 'ok', 'data': <String, dynamic>{'id': 9, 'name': 'Ev yoğurdu'}},
        ));
      },
    ));

    await FoodApiService(FakeDioClient(dio)).createFood(
      const FoodModel(name: 'Ev yoğurdu', defaultUnit: 'g', defaultAmount: 100, calories: 60, protein: 4, carbs: 5, fat: 3),
      localId: 'LF1',
    );

    final Map<String, dynamic> body = sent!.data as Map<String, dynamic>;
    expect(sent!.path, '/nutrition/foods');
    expect(body['name'], 'Ev yoğurdu');
    expect(body['localId'], 'LF1');
  });
}
