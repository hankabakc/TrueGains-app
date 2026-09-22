import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:gymapp_v2/features/nutrition/data/services/diet_api_service.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

  // G-83: kalem sunucuda zaten silinmişse silme başarılıdır; başka bir ret başarı sayılmaz.
  Dio rejectingDio(int status, String message, void Function(RequestOptions options) onPath) {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        onPath(options);
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

  test('silinecek kalem sunucuda yoksa (404) silme başarılı sayılır', () async {
    RequestOptions? captured;
    final dio = rejectingDio(404, 'Öğün öğesi bulunamadı: 7', (options) => captured = options);

    final result = await DietApiService(FakeDioClient(dio)).deleteMealItem(7);

    expect(captured!.method, 'DELETE');
    expect(captured!.path, '/nutrition/meal-logs/items/7');
    expect(result.success, isTrue);
  });

  test('kuyruktaki işaret adresi sunucuya çevrimiçi istekle aynı parametreleri taşır (G-84)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    final List<Uri> sent = <Uri>[];
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        sent.add(options.uri);
        handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options,
          data: <String, dynamic>{'success': true, 'message': 'ok', 'data': <String, dynamic>{'id': 1}},
          statusCode: 200,
        ));
      },
    ));

    await DietApiService(FakeDioClient(dio)).togglePlannedMeal('2026-09-18', 55, true, ingredientIds: [1, 2]);
    // SyncManager kuyruktaki kaydı böyle gönderir: adres + boş gövde.
    await dio.post<Map<String, dynamic>>(
      DietApiService.togglePlannedEndpoint('2026-09-18', 55, true, [1, 2]),
      data: <String, dynamic>{},
    );

    expect(sent[1].path, sent[0].path);
    expect(sent[1].queryParametersAll, sent[0].queryParametersAll);
    expect(sent[1].queryParametersAll['ingredientIds'], <String>['1', '2']);
  });

  test('başkasının kalemini silme (400) başarı sayılmaz', () async {
    final dio = rejectingDio(400, 'Bu kayıt size ait değil!', (_) {});

    final result = await DietApiService(FakeDioClient(dio)).deleteMealItem(7);

    expect(result.success, isFalse);
    expect(result.message, 'Bu kayıt size ait değil!');
  });
}
