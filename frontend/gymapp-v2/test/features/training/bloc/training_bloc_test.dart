import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymapp_v2/core/config/app_config.dart';
import 'package:gymapp_v2/core/di/injection_container.dart';
import 'package:gymapp_v2/core/util/app_logger.dart';
import 'package:gymapp_v2/core/util/no_op_logger_impl.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/features/training/bloc/training_state.dart';
import 'package:gymapp_v2/features/training/repository/training_repository.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';

class MockTrainingRepository extends Mock implements TrainingRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(() {});
  });

  late MockTrainingRepository repository;

  setUp(() {
    if (!sl.isRegistered<AppLogger>()) {
      sl.registerSingleton<AppLogger>(NoOpLoggerImpl());
    }
    repository = MockTrainingRepository();
  });

  tearDown(() {
    if (sl.isRegistered<AppLogger>()) {
      sl.unregister<AppLogger>();
    }
  });

  ApiResponse<T> ok<T>(T data) => ApiResponse<T>(
        success: true,
        message: '',
        data: data,
        timestamp: '',
      );

  ApiResponse<T> fail<T>(String m) => ApiResponse<T>(
        success: false,
        message: m,
        timestamp: '',
      );

  const workoutLog = WorkoutLog(
    setIndex: 1,
    actualWeight: 60.0,
    actualReps: 10,
  );

  final sampleProgram = TrainingBlock(
    id: 1,
    name: 'Test Programı',
    coachName: 'Koç',
    clientId: 10,
    clientName: 'Sporcu',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 2, 1),
    isActive: true,
    isPersonal: true,
    workoutDays: const [],
  );

  group('TrainingBloc - LogWorkoutSet', () {
    blocTest<TrainingBloc, TrainingState>(
      'set repository ye birebir iletiliyor',
      build: () {
        when(() => repository.logSet(42, workoutLog))
            .thenAnswer((_) async => ok(workoutLog));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LogWorkoutSet(42, workoutLog)),
      verify: (_) {
        verify(() => repository.logSet(42, workoutLog)).called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'başarıda durum yayınlanmıyor',
      build: () {
        when(() => repository.logSet(42, workoutLog))
            .thenAnswer((_) async => ok(workoutLog));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LogWorkoutSet(42, workoutLog)),
      expect: () => <TrainingState>[],
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata durumu ekrana taşınıyor',
      build: () {
        when(() => repository.logSet(42, workoutLog))
            .thenThrow(Exception('Bağlantı kesildi'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LogWorkoutSet(42, workoutLog)),
      expect: () => [
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              (s.errorMessage?.contains('Set kaydedilemedi') ?? false),
        ),
      ],
    );
  });

  group('TrainingBloc - LoadMyPrograms', () {
    blocTest<TrainingBloc, TrainingState>(
      'liste yükleniyor',
      build: () {
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadMyPrograms()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.success &&
              s.activePrograms.length == 1,
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'success false hata üretir',
      build: () {
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => fail('Programlar alınamadı'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadMyPrograms()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'istisna hata üretir',
      build: () {
        when(() => repository.getMyActivePrograms())
            .thenThrow(Exception('Ağ arızası'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadMyPrograms()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );
  });

  group('TrainingBloc - ActivateProgram', () {
    blocTest<TrainingBloc, TrainingState>(
      'başarıda program listesi tazeleniyor',
      build: () {
        when(() => repository.activateProgram(7))
            .thenAnswer((_) async => ok<void>(null));
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const ActivateProgram(7)),
      verify: (_) {
        verify(() => repository.activateProgram(7)).called(1);
        verify(() => repository.getMyActivePrograms()).called(1);
      },
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              s.successMessage == 'Program başarıyla aktif edildi.',
        ),
        predicate<TrainingState>((s) => s.status == TrainingStatus.loading),
        predicate<TrainingState>((s) => s.status == TrainingStatus.success),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata mesajı Exception: önekinden arındırılıyor',
      build: () {
        when(() => repository.activateProgram(7))
            .thenThrow(Exception('Sunucu hatası'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const ActivateProgram(7)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              s.errorMessage != null &&
              !s.errorMessage!.contains('Exception:'),
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'hatada isProcessing kapanıyor',
      build: () {
        when(() => repository.activateProgram(7))
            .thenThrow(Exception('Bilinmeyen hata'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const ActivateProgram(7)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>((s) => s.isProcessing == false),
      ],
    );
  });

  group('TrainingBloc - AssignTemplateToClient', () {
    blocTest<TrainingBloc, TrainingState>(
      'iki id doğru sırayla iletiliyor',
      build: () {
        when(() => repository.assignTemplateToClient(7, 99))
            .thenAnswer((_) async => ok(sampleProgram));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const AssignTemplateToClient(templateId: 7, clientId: 99)),
      verify: (_) {
        verify(() => repository.assignTemplateToClient(7, 99)).called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'başarı mesajı program adını taşıyor',
      build: () {
        final gucProgrami = TrainingBlock(
          id: 7,
          name: 'Güç Programı',
          coachName: 'Koç',
          clientId: 99,
          clientName: 'Sporcu',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 1),
          isActive: true,
          isPersonal: false,
          workoutDays: const [],
        );
        when(() => repository.assignTemplateToClient(7, 99))
            .thenAnswer((_) async => ok(gucProgrami));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const AssignTemplateToClient(templateId: 7, clientId: 99)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.successMessage?.contains('Güç Programı') ?? false),
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata mesajı Exception: önekinden arındırılıyor',
      build: () {
        when(() => repository.assignTemplateToClient(7, 99))
            .thenThrow(Exception('Atama yapılamadı'));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const AssignTemplateToClient(templateId: 7, clientId: 99)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              s.errorMessage != null &&
              !s.errorMessage!.contains('Exception:') &&
              s.errorMessage!.contains('Atama yapılamadı'),
        ),
      ],
    );
  });

  group('TrainingBloc - LoadCoachAssignedPrograms', () {
    blocTest<TrainingBloc, TrainingState>(
      'liste yükleniyor',
      build: () {
        when(() => repository.getCoachAssignedPrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadCoachAssignedPrograms()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.success &&
              s.assignedPrograms.length == 1,
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'success false hata üretir',
      build: () {
        when(() => repository.getCoachAssignedPrograms())
            .thenAnswer((_) async => fail('yetkisiz'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadCoachAssignedPrograms()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );
  });

  group('TrainingBloc - LoadCoachTemplates', () {
    blocTest<TrainingBloc, TrainingState>(
      'liste yükleniyor',
      build: () {
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadCoachTemplates()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.success &&
              s.coachTemplates.length == 1,
        ),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'success false hata üretir',
      build: () {
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => fail('yetkisiz'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const LoadCoachTemplates()),
      expect: () => [
        const TrainingState(status: TrainingStatus.loading),
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );
  });

  group('TrainingBloc - CreateCoachTemplate', () {
    blocTest<TrainingBloc, TrainingState>(
      'başarıda şablon listesi tazeleniyor',
      build: () {
        when(() => repository.createCoachTemplate(sampleProgram))
            .thenAnswer((_) async => ok(sampleProgram));
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(CreateCoachTemplate(sampleProgram)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.createCoachTemplate(sampleProgram)).called(1);
        verify(() => repository.getCoachTemplates()).called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata mesajı taşınıyor',
      build: () {
        when(() => repository.createCoachTemplate(sampleProgram))
            .thenThrow(Exception('Sunucu hatası'));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(CreateCoachTemplate(sampleProgram)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.errorMessage?.contains('Şablon oluşturulamadı') ?? false),
        ),
      ],
    );
  });

  group('TrainingBloc - UpdateCoachTemplate', () {
    blocTest<TrainingBloc, TrainingState>(
      'id ve blok birebir iletiliyor',
      build: () {
        when(() => repository.updateCoachTemplate(5, sampleProgram))
            .thenAnswer((_) async => ok(sampleProgram));
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(
        UpdateCoachTemplate(5, sampleProgram),
      ),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.updateCoachTemplate(5, sampleProgram))
            .called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata mesajı taşınıyor',
      build: () {
        when(() => repository.updateCoachTemplate(5, sampleProgram))
            .thenThrow(Exception('Güncelleme hatası'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(
        UpdateCoachTemplate(5, sampleProgram),
      ),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.errorMessage?.contains('Şablon güncellenemedi') ?? false),
        ),
      ],
    );
  });

  group('TrainingBloc - DeleteCoachTemplate', () {
    blocTest<TrainingBloc, TrainingState>(
      'başarıda liste tazeleniyor',
      build: () {
        when(() => repository.deleteCoachTemplate(9))
            .thenAnswer((_) async => ok<void>(null));
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const DeleteCoachTemplate(9)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.deleteCoachTemplate(9)).called(1);
        verify(() => repository.getCoachTemplates()).called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata mesajı taşınıyor',
      build: () {
        when(() => repository.deleteCoachTemplate(9))
            .thenThrow(Exception('Silme hatası'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const DeleteCoachTemplate(9)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.errorMessage?.contains('Şablon silinemedi') ?? false),
        ),
      ],
    );
  });

  group('TrainingBloc - Karakterizasyon (§4.1)', () {
    // DAVRANIŞ NOTU: bugünkü davranış kayda geçiriliyor, doğru kabul edilmiyor.
    // copyWith isProcessing'i koruduğu için başarı sonrası true kalıyor (K5-20).
    blocTest<TrainingBloc, TrainingState>(
      'DAVRANIŞ NOTU: başarılı oluşturmadan sonra isProcessing true kalıyor',
      build: () {
        when(() => repository.createCoachTemplate(sampleProgram))
            .thenAnswer((_) async => ok(sampleProgram));
        when(() => repository.getCoachTemplates())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(CreateCoachTemplate(sampleProgram)),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.isProcessing, isTrue);
      },
    );
  });

  group('TrainingBloc - SubscribeToTrainingUpdates', () {
    blocTest<TrainingBloc, TrainingState>(
      'abonelik doğru clientId ile kuruluyor',
      build: () {
        when(() => repository.subscribeToTrainingUpdates(
              clientId: 55,
              wsUrl: any(named: 'wsUrl'),
              onUpdateReceived: any(named: 'onUpdateReceived'),
            )).thenAnswer((_) async {});
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const SubscribeToTrainingUpdates(55)),
      verify: (_) {
        verify(() => repository.subscribeToTrainingUpdates(
              clientId: 55,
              wsUrl: AppConfig.wsUrl,
              onUpdateReceived: any(named: 'onUpdateReceived'),
            )).called(1);
      },
    );

    test('gelen güncelleme program listesini tazeliyor', () async {
      when(() => repository.subscribeToTrainingUpdates(
            clientId: 55,
            wsUrl: any(named: 'wsUrl'),
            onUpdateReceived: any(named: 'onUpdateReceived'),
          )).thenAnswer((_) async {});
      when(() => repository.getMyActivePrograms())
          .thenAnswer((_) async => ok([sampleProgram]));

      final bloc = TrainingBloc(repository);
      bloc.add(const SubscribeToTrainingUpdates(55));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final captured = verify(() => repository.subscribeToTrainingUpdates(
            clientId: 55,
            wsUrl: AppConfig.wsUrl,
            onUpdateReceived: captureAny(named: 'onUpdateReceived'),
          )).captured.single as void Function();

      captured();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(() => repository.getMyActivePrograms()).called(1);
      await bloc.close();
    });
  });

  group('TrainingBloc - UnsubscribeFromTrainingUpdates', () {
    test('abonelikten çıkılıyor', () async {
      when(() => repository.unsubscribeFromTrainingUpdates())
          .thenAnswer((_) async {});
      final bloc = TrainingBloc(repository);
      bloc.add(const UnsubscribeFromTrainingUpdates());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verify(() => repository.unsubscribeFromTrainingUpdates()).called(1);
      await bloc.close();
    });
  });

  group('TrainingBloc - ClearTrainingMessages', () {
    blocTest<TrainingBloc, TrainingState>(
      'mesajlar temizleniyor',
      build: () => TrainingBloc(repository),
      seed: () => const TrainingState(
        errorMessage: 'Eski hata',
        successMessage: 'Eski başarı',
      ),
      act: (bloc) => bloc.add(const ClearTrainingMessages()),
      expect: () => [
        predicate<TrainingState>(
          (s) => s.errorMessage == null && s.successMessage == null,
        ),
      ],
    );
  });

  group('TrainingBloc - DeleteProgram', () {
    blocTest<TrainingBloc, TrainingState>(
      'başarıda liste tazeleniyor',
      build: () {
        when(() => repository.deletePersonalProgram(3))
            .thenAnswer((_) async => ok<void>(null));
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const DeleteProgram(3)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.deletePersonalProgram(3)).called(1);
        verify(() => repository.getMyActivePrograms()).called(1);
      },
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata durumu',
      build: () {
        when(() => repository.deletePersonalProgram(3))
            .thenThrow(Exception('Silinemedi'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const DeleteProgram(3)),
      expect: () => [
        predicate<TrainingState>(
          (s) =>
              s.status == TrainingStatus.failure &&
              (s.errorMessage?.contains('Program silinemedi') ?? false),
        ),
      ],
    );
  });

  group('TrainingBloc - ApproveOrphanedProgram', () {
    blocTest<TrainingBloc, TrainingState>(
      'keep: true program taşındı',
      build: () {
        when(() => repository.approveOrphanedProgram(4, true))
            .thenAnswer((_) async => ok(sampleProgram));
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const ApproveOrphanedProgram(id: 4, keep: true)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.approveOrphanedProgram(4, true)).called(1);
        verify(() => repository.getMyActivePrograms()).called(1);
      },
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.successMessage?.contains('taşındı') ?? false),
        ),
        predicate<TrainingState>((s) => s.status == TrainingStatus.loading),
        predicate<TrainingState>((s) => s.status == TrainingStatus.success),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'keep: false program silindi',
      build: () {
        when(() => repository.approveOrphanedProgram(4, false))
            .thenAnswer((_) async => ok(sampleProgram));
        when(() => repository.getMyActivePrograms())
            .thenAnswer((_) async => ok([sampleProgram]));
        return TrainingBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const ApproveOrphanedProgram(id: 4, keep: false)),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.approveOrphanedProgram(4, false)).called(1);
        verify(() => repository.getMyActivePrograms()).called(1);
      },
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              (s.successMessage?.contains('silindi') ?? false),
        ),
        predicate<TrainingState>((s) => s.status == TrainingStatus.loading),
        predicate<TrainingState>((s) => s.status == TrainingStatus.success),
      ],
    );

    blocTest<TrainingBloc, TrainingState>(
      'hata durumu',
      build: () {
        when(() => repository.approveOrphanedProgram(4, true))
            .thenThrow(Exception('Sunucu hatası'));
        return TrainingBloc(repository);
      },
      act: (bloc) => bloc.add(const ApproveOrphanedProgram(id: 4, keep: true)),
      expect: () => [
        predicate<TrainingState>((s) => s.isProcessing == true),
        predicate<TrainingState>(
          (s) =>
              s.isProcessing == false &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );
  });
}
