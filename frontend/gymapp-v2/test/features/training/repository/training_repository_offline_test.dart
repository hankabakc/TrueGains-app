import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/dio_client.dart';
import 'package:gymapp_v2/core/network/network_info.dart';
import 'package:gymapp_v2/core/network/sync_manager.dart';
import 'package:gymapp_v2/features/training/data/services/training_api_service.dart';
import 'package:gymapp_v2/features/training/models/completed_set_data.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
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
    when(() => syncManager.addToQueue(any(), any(), method: any(named: 'method'))).thenAnswer((_) async {});
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[]);
    when(() => syncManager.replacePayload(any(), any())).thenAnswer((_) async => true);
    when(() => syncManager.removePending(any())).thenAnswer((_) async => true);
    when(() => syncManager.syncPendingData()).thenAnswer((_) async {});
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

  // --- G-74: kişisel program internetsiz (oluştur, düzenle, sil) ---

  const String programs = TrainingApiService.personalProgramsPath;
  final RegExp uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  TrainingBlock program({int id = 0, String name = 'Program', String? localId, int? version, bool isActive = false}) {
    return TrainingBlock(
      id: id,
      name: name,
      coachName: 'Kişisel Program',
      clientId: 0,
      clientName: '',
      startDate: DateTime(2026, 9, 23),
      endDate: DateTime(2026, 10, 21),
      isActive: isActive,
      isPersonal: true,
      workoutDays: const <WorkoutDay>[],
      version: version,
      localId: localId,
    );
  }

  ApiResponse<T> ok<T>(T? data) => ApiResponse<T>(success: true, message: '', data: data, timestamp: '');

  PendingRecord queued(String key, String endpoint, String method, Map<String, dynamic> payload) =>
      PendingRecord(key: key, endpoint: endpoint, method: method, payload: payload);

  test('bağlantı yokken yeni program cihaz kimliğiyle kuyruğa girer, bekliyor olarak döner', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final ApiResponse<TrainingBlock> res = await repository.createPersonalProgram(program(name: 'Yerel'));

    final Map<String, dynamic> payload =
        verify(() => syncManager.addToQueue(programs, captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['local_id'], matches(uuidPattern));
    expect(payload['name'], equals('Yerel'));
    expect(res.success, isTrue);
    expect(res.data!.isQueued, isTrue);
    expect(res.data!.localId, equals(payload['local_id']));
    verifyNever(() => api.createPersonalProgram(any()));
  });

  test('bağlantı varken yeni program cihaz kimliğiyle doğrudan gider', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.createPersonalProgram(any())).thenAnswer((_) async => ok<TrainingBlock>(null));

    await repository.createPersonalProgram(program());

    final Map<String, dynamic> payload =
        verify(() => api.createPersonalProgram(captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['local_id'], matches(uuidPattern));
    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('kuyruktaki programın düzenlemesi aynı kaydın yükünü değiştirir, ikinci program açılmaz', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{'name': 'Eski', 'local_id': 'L1'}),
    ]);

    final ApiResponse<TrainingBlock> res =
        await repository.createPersonalProgram(program(name: 'Düzenlendi', localId: 'L1'));

    final Map<String, dynamic> payload =
        verify(() => syncManager.replacePayload('k1', captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['name'], equals('Düzenlendi'));
    expect(payload['local_id'], equals('L1'));
    expect(res.success, isTrue);
    verifyNever(() => syncManager.addToQueue(any(), any()));
    verifyNever(() => api.createPersonalProgram(any()));
  });

  test('kuyruktaki program tam o an gönderildiyse düzenleme hata döner, sessizce kaybolmaz', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{'local_id': 'L1'}),
    ]);
    when(() => syncManager.replacePayload(any(), any())).thenAnswer((_) async => false);

    final ApiResponse<TrainingBlock> res = await repository.createPersonalProgram(program(localId: 'L1'));

    expect(res.success, isFalse);
    verifyNever(() => api.createPersonalProgram(any()));
    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('bağlantı yokken düzenleme sürümüyle birlikte PUT olarak kuyruğa girer', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final ApiResponse<TrainingBlock> res =
        await repository.updatePersonalProgram(7, program(id: 7, name: 'Yeni', version: 3));

    final List<dynamic> captured = verify(
      () => syncManager.addToQueue(captureAny(), captureAny(), method: captureAny(named: 'method')),
    ).captured;
    expect(captured[0], equals('$programs/7'));
    expect((captured[1] as Map<String, dynamic>)['version'], equals(3));
    expect((captured[1] as Map<String, dynamic>)['name'], equals('Yeni'));
    expect(captured[2], equals(SyncManager.methodPut));
    expect(res.data!.isQueued, isTrue);
    verifyNever(() => api.updatePersonalProgram(any(), any()));
  });

  test('bağlantı varken düzenleme doğrudan gider', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.updatePersonalProgram(any(), any())).thenAnswer((_) async => ok<TrainingBlock>(null));

    await repository.updatePersonalProgram(7, program(id: 7, version: 3));

    verify(() => api.updatePersonalProgram(7, any())).called(1);
    verifyNever(() => syncManager.addToQueue(any(), any(), method: any(named: 'method')));
  });

  test('gönderilmemiş düzenlemesi olan programda yeni düzenleme o kaydın yükünü değiştirir, ilk sürüm korunur', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k7', '$programs/7', SyncManager.methodPut, <String, dynamic>{'name': 'İlk', 'version': 3}),
    ]);

    await repository.updatePersonalProgram(7, program(id: 7, name: 'İkinci', version: 4));

    final Map<String, dynamic> payload =
        verify(() => syncManager.replacePayload('k7', captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['name'], equals('İkinci'));
    expect(payload['version'], equals(3));
    verifyNever(() => syncManager.addToQueue(any(), any(), method: any(named: 'method')));
  });

  test('bağlantı yokken silme kuyruğa girer', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);

    final ApiResponse<void> res = await repository.deletePersonalProgram(7);

    verify(() => syncManager.addToQueue('$programs/7', <String, dynamic>{}, method: SyncManager.methodDelete))
        .called(1);
    expect(res.success, isTrue);
    verifyNever(() => api.deletePersonalProgram(any()));
  });

  test('sunucuya gitmemiş programın silinmesi oluşturma kaydını kuyruktan çıkarır, sunucuya istek gitmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k0', programs, SyncManager.methodPost, <String, dynamic>{'local_id': 'L0'}),
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{'local_id': 'L1'}),
    ]);

    final ApiResponse<void> res = await repository.deletePersonalProgram(0, localId: 'L1');

    verify(() => syncManager.removePending('k1')).called(1);
    verifyNever(() => syncManager.removePending('k0'));
    expect(res.success, isTrue);
    verifyNever(() => api.deletePersonalProgram(any()));
    verifyNever(() => syncManager.addToQueue(any(), any(), method: any(named: 'method')));
  });

  test('silinen programın gönderilmemiş düzenlemesi kuyruktan çıkar', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.deletePersonalProgram(any())).thenAnswer((_) async => ok<void>(null));
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k7', '$programs/7', SyncManager.methodPut, <String, dynamic>{'name': 'Düzenleme'}),
      queued('k8', '$programs/8', SyncManager.methodPut, <String, dynamic>{'name': 'Başka'}),
    ]);

    await repository.deletePersonalProgram(7);

    verify(() => syncManager.removePending('k7')).called(1);
    verifyNever(() => syncManager.removePending('k8'));
  });

  test('listede kuyruktaki program bekliyor olarak eklenir, düzenlenen yeni hâliyle görünür, silinen gizlenir', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => api.getMyActivePrograms()).thenAnswer(
      (_) async => ok<List<TrainingBlock>>(<TrainingBlock>[
        program(id: 7, name: 'Sunucudaki', version: 3, isActive: true),
        program(id: 8, name: 'Silinecek'),
      ]),
    );
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k7', '$programs/7', SyncManager.methodPut, program(id: 7, name: 'Düzenlendi', version: 3).toJson()),
      queued('k8', '$programs/8', SyncManager.methodDelete, <String, dynamic>{}),
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{...program(name: 'Yerel').toJson(), 'local_id': 'L1'}),
      queued('w1', TrainingApiService.sessionsPath, SyncManager.methodPost, <String, dynamic>{'name': 'Antrenman'}),
    ]);

    final List<TrainingBlock> list = (await repository.getMyActivePrograms()).data!;

    expect(list.map((TrainingBlock p) => p.name).toList(), equals(<String>['Düzenlendi', 'Yerel']));
    expect(list[0].id, equals(7));
    expect(list[0].isActive, isTrue);
    expect(list[0].isQueued, isTrue);
    expect(list[1].id, equals(0));
    expect(list[1].localId, equals('L1'));
    expect(list[1].isQueued, isTrue);
  });

  test('internetsiz ve önbelleksizse yalnızca kuyruktaki programlar; bağlantı varken sunucu hatası örtülmez', () async {
    when(() => api.getMyActivePrograms())
        .thenAnswer((_) async => ApiResponse<List<TrainingBlock>>.error('Antrenman servisi hatası'));
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{...program(name: 'Yerel').toJson(), 'local_id': 'L1'}),
    ]);

    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    final ApiResponse<List<TrainingBlock>> offline = await repository.getMyActivePrograms();
    expect(offline.success, isTrue);
    expect(offline.data!.single.name, equals('Yerel'));

    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    final ApiResponse<List<TrainingBlock>> online = await repository.getMyActivePrograms();
    expect(online.success, isFalse);
  });

  // --- G-74 (b): internetsiz oluşturulan programı etkinleştirme ve onunla antrenman ---

  CompletedSetData setOf(int workoutExerciseId) => CompletedSetData(
        workoutExerciseId: workoutExerciseId,
        exerciseName: 'Squat',
        setIndex: 1,
        weight: 80,
        reps: 10,
        durationSeconds: 30,
        completedAt: DateTime(2026, 9, 23),
      );

  test('kuyruktaki programla antrenman bağlantı varken de kuyruğa girer, kimliksiz program/gün gönderilmez', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    await repository.logWorkoutSession(
      dayName: 'Pazartesi',
      totalSeconds: 600,
      sets: <CompletedSetData>[setOf(-501)],
      trainingBlockId: 0,
      workoutDayId: -11,
    );

    final Map<String, dynamic> payload =
        verify(() => syncManager.addToQueue(TrainingApiService.sessionsPath, captureAny())).captured.single
            as Map<String, dynamic>;
    expect(payload['trainingBlockId'], isNull);
    expect(payload['workoutDayId'], isNull);
    expect(((payload['logs'] as List<dynamic>).single as Map<String, dynamic>)['workoutExerciseId'], equals(-501));
    verify(() => syncManager.syncPendingData()).called(1);
    verifyNever(() => api.logWorkoutSession(any()));
  });

  test('sunucudaki programla antrenman program ve gün kimliğiyle doğrudan gider', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.logWorkoutSession(any()))
        .thenAnswer((_) async => ApiResponse<void>(success: true, message: '', timestamp: ''));

    await repository.logWorkoutSession(
      dayName: 'Pazartesi',
      totalSeconds: 600,
      sets: <CompletedSetData>[setOf(1000)],
      trainingBlockId: 7,
      workoutDayId: 70,
    );

    final Map<String, dynamic> payload =
        verify(() => api.logWorkoutSession(captureAny())).captured.single as Map<String, dynamic>;
    expect(payload['trainingBlockId'], equals(7));
    expect(payload['workoutDayId'], equals(70));
    verifyNever(() => syncManager.addToQueue(any(), any()));
  });

  test('sunucuya gitmemiş program yerel kimliğiyle etkinleşir, kuyruğa girer ve bağlantı varsa hemen gönderilir', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => true);

    final ApiResponse<void> res = await repository.activateProgram(0, localId: 'L1');

    verify(() => syncManager.addToQueue('${TrainingApiService.activatePath}/local/L1', <String, dynamic>{})).called(1);
    verify(() => syncManager.syncPendingData()).called(1);
    verifyNever(() => api.activateProgram(any()));
    expect(res.success, isTrue);
  });

  test('bağlantı yokken sunucudaki programın etkinleştirmesi kuyruğa girer; varken doğrudan gider', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    await repository.activateProgram(7);
    verify(() => syncManager.addToQueue('${TrainingApiService.activatePath}/7', <String, dynamic>{})).called(1);
    verifyNever(() => api.activateProgram(any()));

    when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    when(() => api.activateProgram(any())).thenAnswer((_) async => ok<void>(null));
    await repository.activateProgram(7);
    verify(() => api.activateProgram(7)).called(1);
  });

  test('listede kuyruktaki son etkinleştirme tek aktif programı belirler', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => api.getMyActivePrograms()).thenAnswer(
      (_) async => ok<List<TrainingBlock>>(<TrainingBlock>[
        program(id: 7, name: 'Eski aktif', isActive: true),
        program(id: 8, name: 'Diğer'),
      ]),
    );
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{...program(name: 'Yerel').toJson(), 'local_id': 'L1'}),
      queued('a8', '${TrainingApiService.activatePath}/8', SyncManager.methodPost, <String, dynamic>{}),
      queued('a1', '${TrainingApiService.activatePath}/local/L1', SyncManager.methodPost, <String, dynamic>{}),
    ]);

    final List<TrainingBlock> list = (await repository.getMyActivePrograms()).data!;

    expect(
      list.map((TrainingBlock p) => '${p.name}:${p.isActive}').toList(),
      equals(<String>['Eski aktif:false', 'Diğer:false', 'Yerel:true']),
    );
  });

  test('sunucuya gitmemiş program silinince kuyruktaki etkinleştirmesi de çıkar', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('k1', programs, SyncManager.methodPost, <String, dynamic>{'local_id': 'L1'}),
      queued('a1', '${TrainingApiService.activatePath}/local/L1', SyncManager.methodPost, <String, dynamic>{}),
      queued('a2', '${TrainingApiService.activatePath}/local/L2', SyncManager.methodPost, <String, dynamic>{}),
    ]);

    await repository.deletePersonalProgram(0, localId: 'L1');

    verify(() => syncManager.removePending('k1')).called(1);
    verify(() => syncManager.removePending('a1')).called(1);
    verifyNever(() => syncManager.removePending('a2'));
  });

  test('sunucudaki program silinince kuyruktaki etkinleştirmesi de çıkar', () async {
    when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    when(() => syncManager.pendingRecords()).thenReturn(<PendingRecord>[
      queued('a7', '${TrainingApiService.activatePath}/7', SyncManager.methodPost, <String, dynamic>{}),
      queued('a8', '${TrainingApiService.activatePath}/8', SyncManager.methodPost, <String, dynamic>{}),
    ]);

    await repository.deletePersonalProgram(7);

    verify(() => syncManager.removePending('a7')).called(1);
    verifyNever(() => syncManager.removePending('a8'));
  });
}
