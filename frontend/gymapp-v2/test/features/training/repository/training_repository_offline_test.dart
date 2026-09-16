import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/training/data/services/training_api_service.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockTrainingApiService extends Mock implements TrainingApiService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockSyncManager extends Mock implements SyncManager {}
class MockDioClient extends Mock implements DioClient {}
class MockDio extends Mock implements Dio {}

void main() {
  late MockTrainingApiService api;
  late MockNetworkInfo networkInfo;
  late MockSyncManager syncManager;
  late TrainingRepository repository;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = MockTrainingApiService();
    networkInfo = MockNetworkInfo();
    syncManager = MockSyncManager();
    repository = TrainingRepository(
      apiService: api,
      networkInfo: networkInfo,
      syncManager: syncManager,
    );
    when(() => syncManager.addToQueue(any(), any())).thenAnswer((_) async {});
  });

  test('bağlantı yokken antrenman gerçek oturum ucuna kuyruklanır', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    await repository.logWorkoutSession(
      dayName: 'Gün 1',
      totalSeconds: 60,
      sets: const <CompletedSetData>[],
    );

    final captured = verify(() => syncManager.addToQueue(captureAny(), any())).captured.single as String;
    expect(captured, equals('/training/sessions'));
    expect(captured, equals(TrainingApiService.sessionsPath));
    verifyNever(() => api.logWorkoutSession(any()));
  });

  test('bağlantı varken kuyruğa dokunulmaz', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.logWorkoutSession(any())).thenAnswer(
      (_) async => ApiResponse<void>(
        success: true,
        message: '',
        timestamp: '2026-01-01T00:00:00Z',
      ),
    );

    await repository.logWorkoutSession(
      dayName: 'Gün 1',
      totalSeconds: 60,
      sets: const <CompletedSetData>[],
    );

    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('api servisi antrenmanı aynı uca gönderir', () async {
    final dioClient = MockDioClient();
    final dio = MockDio();
    when(() => dioClient.dio).thenReturn(dio);
    final service = TrainingApiService(dioClient);

    when(() => dio.post<Map<String, dynamic>>('/training/sessions', data: any(named: 'data')))
        .thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        statusCode: 200,
        data: {'success': true, 'message': 'ok', 'timestamp': '2026-01-01T00:00:00Z'},
        requestOptions: RequestOptions(path: '/training/sessions'),
      ),
    );

    await service.logWorkoutSession({'a': 1});

    verify(() => dio.post<Map<String, dynamic>>('/training/sessions', data: {'a': 1})).called(1);
  });

  test('çevrimdışı antrenman yerel kimlik taşır', () async {
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    await repository.logWorkoutSession(
      dayName: 'Gün 1',
      totalSeconds: 60,
      sets: const <CompletedSetData>[],
    );

    final payload = verify(() => syncManager.addToQueue(any(), captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['localId'], matches(uuidPattern));
  });

  test('çevrimiçi antrenman yerel kimlik taşır', () async {
    final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.logWorkoutSession(any())).thenAnswer(
      (_) async => ApiResponse<void>(
        success: true,
        message: '',
        timestamp: '2026-01-01T00:00:00Z',
      ),
    );

    await repository.logWorkoutSession(
      dayName: 'Gün 1',
      totalSeconds: 60,
      sets: const <CompletedSetData>[],
    );

    final payload = verify(() => api.logWorkoutSession(captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['localId'], matches(uuidPattern));
  });
}
