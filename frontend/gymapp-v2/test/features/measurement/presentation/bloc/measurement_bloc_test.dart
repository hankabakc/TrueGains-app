import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_state.dart';
import 'package:gymapp_v2/features/measurement/repository/measurement_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  late MockMeasurementRepository repository;

  final m1 = Measurement(
    id: 1,
    weight: 75.0,
    height: 180.0,
    createdAt: DateTime(2026, 1, 1),
    isSharedWithCoach: false,
  );

  final m2 = Measurement(
    id: 2,
    weight: 74.5,
    height: 180.0,
    createdAt: DateTime(2026, 1, 2),
    isSharedWithCoach: false,
  );

  setUp(() {
    repository = MockMeasurementRepository();
  });

  MeasurementBloc buildBloc() => MeasurementBloc(repository);

  group('MeasurementBloc', () {
    blocTest<MeasurementBloc, MeasurementState>(
      'liste yükleniyor',
      build: () {
        when(() => repository.getMyMeasurements(clientId: any(named: 'clientId')))
            .thenAnswer((_) async => [m1, m2]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMeasurements()),
      expect: () => [
        MeasurementLoading(),
        MeasurementLoaded(measurements: [m1, m2]),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.measurements, hasLength(2));
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'yükleme hatası mesajı taşıyor',
      build: () {
        when(() => repository.getMyMeasurements(clientId: any(named: 'clientId')))
            .thenThrow(Exception('koptu'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMeasurements()),
      expect: () => [
        MeasurementLoading(),
        isA<MeasurementError>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementError>());
        final state = bloc.state as MeasurementError;
        expect(state.message, isNotEmpty);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'clientId repository çağrısına birebir geçiyor',
      build: () {
        // any(named:) BİLEREK kullanılmıyor: bu testin tek amacı değerin
        // taşındığını sabitlemek. Koçun sporcu ölçümlerini görmesi buna bağlı;
        // iletilmezse koç kendi ölçümlerini görür ve fark etmez.
        when(() => repository.getMyMeasurements(clientId: 42))
            .thenAnswer((_) async => [m1]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMeasurements(clientId: 42)),
      expect: () => [
        MeasurementLoading(),
        MeasurementLoaded(measurements: [m1]),
      ],
      verify: (bloc) {
        verify(() => repository.getMyMeasurements(clientId: 42)).called(1);
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.measurements, hasLength(1));
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'silme başarılıysa liste yeniden çekiliyor',
      build: () {
        when(() => repository.deleteMeasurement(5))
            .thenAnswer((_) async {});
        when(() => repository.getMyMeasurements(clientId: any(named: 'clientId')))
            .thenAnswer((_) async => [m1, m2]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteMeasurement(5)),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        verify(() => repository.deleteMeasurement(5)).called(1);
        verify(() => repository.getMyMeasurements(clientId: any(named: 'clientId'))).called(1);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'silme hatasında liste korunuyor, hata mesajı taşınıyor',
      seed: () => MeasurementLoaded(measurements: [m1, m2]),
      build: () {
        when(() => repository.deleteMeasurement(any()))
            .thenThrow(Exception('silinemedi'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteMeasurement(1)),
      expect: () => [
        isA<MeasurementLoaded>()
            .having((s) => s.measurements, 'measurements', hasLength(2))
            .having((s) => s.deleteError, 'deleteError', isNotEmpty),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.measurements, hasLength(2));
        expect(state.deleteError, isNotEmpty);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'liste yokken silme hatasında MeasurementError yayınlanıyor',
      build: () {
        when(() => repository.deleteMeasurement(any()))
            .thenThrow(Exception('silinemedi'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const DeleteMeasurement(1)),
      expect: () => [
        isA<MeasurementError>(),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementError>());
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'hata bir sonraki durumda temizleniyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        deleteError: 'Önceki silme hatası',
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(ToggleSelectionMode()),
      expect: () => [
        isA<MeasurementLoaded>()
            .having((s) => s.deleteError, 'deleteError', isNull),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.deleteError, isNull);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'seçim modu kapanınca seçilenler sıfırlanıyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        isSelectionMode: true,
        selectedIds: const {1, 2},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(ToggleSelectionMode()),
      expect: () => [
        MeasurementLoaded(
          measurements: [m1, m2],
          isSelectionMode: false,
          selectedIds: const {},
        ),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.isSelectionMode, isFalse);
        expect(state.selectedIds, isEmpty);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'seçilmemiş ölçüm seçime ekleniyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        isSelectionMode: true,
        selectedIds: const {},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const ToggleMeasurementSelection(1)),
      expect: () => [
        isA<MeasurementLoaded>()
            .having((s) => s.selectedIds, 'selectedIds', const {1}),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.selectedIds, const {1});
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'seçili ölçüm seçimden çıkıyor, diğeri etkilenmiyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        isSelectionMode: true,
        selectedIds: const {1, 2},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const ToggleMeasurementSelection(1)),
      expect: () => [
        isA<MeasurementLoaded>()
            .having((s) => s.selectedIds, 'selectedIds', const {2}),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        // isEmpty ile ölçülmez: "hepsini temizle" hatası o zaman yakalanmaz.
        expect(state.selectedIds, const {2});
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'liste yüklenmemişken seçim olayı yok sayılıyor',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const ToggleMeasurementSelection(1)),
      expect: () => <MeasurementState>[],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementInitial>());
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'paylaşım seçilenleri işaretliyor ve seçimi temizliyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        selectedIds: const {1},
        isSelectionMode: true,
      ),
      build: () {
        when(() => repository.shareMeasurements([1]))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(ShareSelectedMeasurements()),
      expect: () => [
        isA<MeasurementLoaded>()
            .having((s) => s.isSharing, 'isSharing', true)
            .having((s) => s.selectedIds, 'selectedIds', const {1}),
        isA<MeasurementLoaded>()
            .having((s) => s.isSharing, 'isSharing', false)
            .having((s) => s.isSelectionMode, 'isSelectionMode', false)
            .having((s) => s.selectedIds, 'selectedIds', isEmpty)
            .having((s) => s.shareSuccess, 'shareSuccess', true),
      ],
      verify: (bloc) {
        expect(bloc.state, isA<MeasurementLoaded>());
        final state = bloc.state as MeasurementLoaded;
        expect(state.measurements.firstWhere((m) => m.id == 1).isSharedWithCoach, isTrue);
        expect(state.measurements.firstWhere((m) => m.id == 2).isSharedWithCoach, isFalse);
        expect(state.selectedIds, isEmpty);
        expect(state.isSelectionMode, isFalse);
        expect(state.isSharing, isFalse);
        expect(state.shareSuccess, isTrue);
        verify(() => repository.shareMeasurements([1])).called(1);
      },
    );

    blocTest<MeasurementBloc, MeasurementState>(
      'seçim boşken paylaşım sunucuya gitmiyor',
      seed: () => MeasurementLoaded(
        measurements: [m1, m2],
        selectedIds: const {},
      ),
      build: () => buildBloc(),
      act: (bloc) => bloc.add(ShareSelectedMeasurements()),
      expect: () => <MeasurementState>[],
      verify: (bloc) {
        verifyNever(() => repository.shareMeasurements(any()));
      },
    );
  });
}
