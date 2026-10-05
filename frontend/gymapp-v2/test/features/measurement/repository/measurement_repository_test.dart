import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/features/measurement/repository/measurement_repository.dart';
import 'package:mocktail/mocktail.dart';

class FakeDioClient implements DioClient {
  @override
  Dio dio;

  FakeDioClient(this.dio);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockSyncManager extends Mock implements SyncManager {}

/// Ölçüm ekleme ve silme internetsiz (KR13, G-86): kuyruğa girer, liste bekleyeni gösterir; silmede 204 başarıdır.
void main() {
  final RegExp uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  late MockNetworkInfo networkInfo;
  late MockSyncManager syncManager;
  late List<RequestOptions> sent;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  setUp(() {
    networkInfo = MockNetworkInfo();
    syncManager = MockSyncManager();
    sent = <RequestOptions>[];
    when(
      () => syncManager.addToQueue(any(), any(), method: any(named: 'method'), preview: any(named: 'preview')),
    ).thenAnswer((_) async {});
    when(() => syncManager.pendingRecords()).thenReturn(const <PendingRecord>[]);
  });

  /// Sunucu yerine geçen Dio: her isteği kaydeder, verilen durum koduyla cevaplar ya da bağlantı hatası verir.
  MeasurementRepository repositoryWith({int status = 200, Object? data, bool unreachable = false}) {
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        sent.add(options);
        if (unreachable) {
          handler.reject(DioException(requestOptions: options, type: DioExceptionType.connectionError));
        } else if (status >= 400) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(requestOptions: options, statusCode: status, data: data),
          ));
        } else {
          handler.resolve(Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: status,
            data: data as Map<String, dynamic>?,
          ));
        }
      },
    ));
    return MeasurementRepository(FakeDioClient(dio), networkInfo, syncManager);
  }

  Map<String, dynamic> page(List<Map<String, dynamic>> content) => <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{'content': content},
      };

  test('bağlantı yokken ölçüm kimlik ve ekleme anıyla kuyruğa girer, sunucuya gidilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    final MeasurementRepository repository = repositoryWith();
    final DateTime before = DateTime.now().toUtc();

    final Measurement result = await repository.addMeasurement(Measurement(weight: 72.5));

    final Map<String, dynamic> payload = verify(
      () => syncManager.addToQueue('/measurements', captureAny(), method: SyncManager.methodPost, preview: any(named: 'preview')),
    ).captured.single as Map<String, dynamic>;
    expect(payload['weight'], 72.5);
    expect(payload['localId'], matches(uuidPattern));
    expect(DateTime.parse(payload['createdAt'] as String).difference(before).inMinutes.abs(), lessThan(1));
    expect(sent, isEmpty);
    expect(result.weight, 72.5);
  });

  test('bağlantı varken ölçüm cihaz kimliğiyle gider, zamanı sunucu verir', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    final MeasurementRepository repository = repositoryWith(
      data: <String, dynamic>{'success': true, 'message': 'ok', 'data': <String, dynamic>{'id': 3, 'weight': 72.5}},
    );

    await repository.addMeasurement(Measurement(weight: 72.5));

    final Map<String, dynamic> body = sent.single.data as Map<String, dynamic>;
    expect(body['localId'], matches(uuidPattern));
    expect(body.containsKey('createdAt'), isFalse);
    verifyNever(
      () => syncManager.addToQueue(any(), any(), method: any(named: 'method'), preview: any(named: 'preview')),
    );
  });

  test('bağlantı yokken silme DELETE olarak kuyruğa girer, sunucuya gidilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    final MeasurementRepository repository = repositoryWith();

    await repository.deleteMeasurement(5);

    verify(
      () => syncManager.addToQueue(
        '/measurements/5',
        <String, dynamic>{},
        method: SyncManager.methodDelete,
        preview: any(named: 'preview'),
      ),
    ).called(1);
    expect(sent, isEmpty);
  });

  test('sunucu silmede 204 dönünce silme başarılı sayılır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    final MeasurementRepository repository = repositoryWith(status: 204);

    await expectLater(repository.deleteMeasurement(5), completes);
    expect(sent.single.method, 'DELETE');
    expect(sent.single.path, '/measurements/5');
  });

  test('silinecek ölçüm sunucuda yoksa (404) silme başarılı sayılır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    final MeasurementRepository repository = repositoryWith(status: 404);

    await expectLater(repository.deleteMeasurement(5), completes);
  });

  test('kendi listemde bekleyen ölçüm en üstte bekliyor olarak görünür, silinmeyi bekleyen gizlenir', () async {
    when(() => syncManager.pendingRecords()).thenReturn(const <PendingRecord>[
      PendingRecord(
        key: 'q1',
        endpoint: '/measurements',
        method: SyncManager.methodPost,
        payload: <String, dynamic>{'weight': 70.0, 'createdAt': '2026-09-18T06:00:00.000Z', 'localId': 'L1'},
      ),
      PendingRecord(key: 'd1', endpoint: '/measurements/7', method: SyncManager.methodDelete, payload: <String, dynamic>{}),
    ]);
    final MeasurementRepository repository = repositoryWith(
      data: page(<Map<String, dynamic>>[
        <String, dynamic>{'id': 8, 'weight': 71.0},
        <String, dynamic>{'id': 7, 'weight': 72.0},
      ]),
    );

    final List<Measurement> list = await repository.getMyMeasurements();

    expect(list.map((Measurement m) => m.id).toList(), <int?>[null, 8]);
    expect(list.first.isPending, isTrue);
    expect(list.first.queueKey, 'q1');
    expect(list.first.weight, 70.0);
  });

  test('internetsizken liste önbellekte yoksa yalnızca bekleyen ölçümler görünür', () async {
    when(() => syncManager.pendingRecords()).thenReturn(const <PendingRecord>[
      PendingRecord(
        key: 'q1',
        endpoint: '/measurements',
        method: SyncManager.methodPost,
        payload: <String, dynamic>{'weight': 70.0, 'localId': 'L1'},
      ),
    ]);
    final MeasurementRepository repository = repositoryWith(unreachable: true);

    final List<Measurement> list = await repository.getMyMeasurements();

    expect(list.single.queueKey, 'q1');
  });

  test('koçun gördüğü sporcu listesine kendi kuyruğum karışmaz', () async {
    final MeasurementRepository repository = repositoryWith(
      data: page(<Map<String, dynamic>>[
        <String, dynamic>{'id': 8, 'weight': 71.0},
      ]),
    );

    final List<Measurement> list = await repository.getMyMeasurements(clientId: 42);

    expect(list.map((Measurement m) => m.id).toList(), <int?>[8]);
    verifyNever(() => syncManager.pendingRecords());
  });

  test('getMyMeasurements 409 durumunda sunucu mesajı varsa fırlatır, yoksa çakışma metniyle fırlatır', () async {
    final MeasurementRepository repoWithMsg = repositoryWith(
      status: 409,
      data: <String, dynamic>{
        'success': false,
        'message': 'Bu antrenörü zaten değerlendirdiniz.',
      },
    );

    expect(
      () => repoWithMsg.getMyMeasurements(),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('Bu antrenörü zaten değerlendirdiniz.'),
      )),
    );

    final MeasurementRepository repoNullData = repositoryWith(status: 409, data: null);

    expect(
      () => repoNullData.getMyMeasurements(),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'message',
        contains('Eş zamanlı güncelleme çakışması: Veri başka bir yerde güncellenmiş. Lütfen sayfayı yenileyip tekrar deneyin.'),
      )),
    );
  });
}
