import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/add_measurement/add_measurement_cubit.dart';
import 'package:gymapp_v2/features/measurement/repository/measurement_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

class _FakeMeasurement extends Fake implements Measurement {}

/// Ölçüm girişi ekranı.
///
/// Kullanıcı 13 alanı elle giriyor. İki risk var: kaydetme başarısız olduğu
/// hâlde başarı gösterilmesi (kullanıcı kaydettim sanıp ekrandan çıkar, veri
/// gider) ve bugünün ölçümü yüklenirken değerlerin yanlış alana yerleşmesi.
void main() {
  late MockMeasurementRepository repository;

  Measurement todayRecord() {
    return Measurement(
      id: 1,
      weight: 80.5,
      height: 180,
      bodyFatPct: 18.2,
      muscleMass: 35.1,
      chest: 100,
      waist: 85,
      shoulders: 120,
      leftArm: 35,
      rightArm: 36,
      leftLeg: 55,
      rightLeg: 56,
      hips: 95,
      notes: 'Sabah ölçümü',
    );
  }

  setUpAll(() {
    registerFallbackValue(_FakeMeasurement());
  });

  setUp(() {
    repository = MockMeasurementRepository();
  });

  group('kaydetme', () {
    test('başarısız olduğunda başarı gösterilmez', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.addMeasurement(any())).thenThrow(Exception('Sunucu hatası'));

      await cubit.saveMeasurement({'weight': 80.5});

      // isSuccess true olsaydı ekran kapanır, kullanıcı kaydettim sanır ve
      // girdiği ölçüm kaybolurdu.
      expect(cubit.state.isSuccess, isFalse);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.isSaving, isFalse);
    });

    test('başarılı olduğunda hata bırakmaz', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.addMeasurement(any())).thenAnswer((_) async => todayRecord());

      await cubit.saveMeasurement({'weight': 80.5});

      expect(cubit.state.isSuccess, isTrue);
      expect(cubit.state.error, isNull);
      expect(cubit.state.isSaving, isFalse);
    });

    test('yeniden denemede önceki hata temizlenir', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.addMeasurement(any())).thenThrow(Exception('Sunucu hatası'));
      await cubit.saveMeasurement({'weight': 80.5});
      expect(cubit.state.error, isNotNull);

      when(() => repository.addMeasurement(any())).thenAnswer((_) async => todayRecord());
      await cubit.saveMeasurement({'weight': 80.5});

      // Eski hata ekranda asılı kalmamalı.
      expect(cubit.state.error, isNull);
      expect(cubit.state.isSuccess, isTrue);
    });
  });

  group('bugünün ölçümünü yükleme', () {
    test('her değer kendi alanına yerleşir', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.getTodayMeasurement()).thenAnswer((_) async => todayRecord());

      await cubit.loadTodayData();

      final data = cubit.state.initialData!;
      // Alanlar karışırsa kullanıcı kendi ölçüsünü yanlış satırda görür ve
      // düzeltmeden kaydederse geçmişi bozar.
      expect(data['weight'], '80.5');
      expect(data['height'], '180.0');
      expect(data['bodyFatPct'], '18.2');
      expect(data['waist'], '85.0');
      expect(data['leftArm'], '35.0');
      expect(data['rightArm'], '36.0');
      expect(data['leftLeg'], '55.0');
      expect(data['rightLeg'], '56.0');
      expect(data['notes'], 'Sabah ölçümü');
    });

    test('bugün ölçüm yoksa form boş kalır', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.getTodayMeasurement()).thenAnswer((_) async => null);

      await cubit.loadTodayData();

      expect(cubit.state.initialData, isNull);
    });

    test('yükleme hatası ekranı kilitlemez', () async {
      final cubit = AddMeasurementCubit(repository);
      when(() => repository.getTodayMeasurement()).thenThrow(Exception('Ağ hatası'));

      await cubit.loadTodayData();

      // Önceki ölçüm getirilemese de kullanıcı yeni ölçüm girebilmeli.
      expect(cubit.state.error, isNull);
      expect(cubit.state.isSaving, isFalse);
    });
  });
}
