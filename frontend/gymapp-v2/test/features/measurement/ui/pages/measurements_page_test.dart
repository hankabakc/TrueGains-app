import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/measurement/models/measurement.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_bloc.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_event.dart';
import 'package:gymapp_v2/features/measurement/presentation/bloc/measurement/measurement_state.dart';
import 'package:gymapp_v2/features/measurement/ui/pages/measurements_page.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementBloc extends MockBloc<MeasurementEvent, MeasurementState> implements MeasurementBloc {}

/// Ölçüm listesi (G-86): kuyrukta bekleyen ölçüm işaretlidir, kaydırınca kuyruktan çıkar, koçla paylaşım için seçilemez.
void main() {
  late MockMeasurementBloc bloc;

  final Measurement pending = Measurement(weight: 70.0, createdAt: DateTime(2026, 9, 18, 9), queueKey: 'q1');
  final Measurement saved = Measurement(id: 8, weight: 71.0, createdAt: DateTime(2026, 9, 10, 9));

  setUpAll(() {
    registerFallbackValue(const LoadMeasurements());
  });

  setUp(() {
    bloc = MockMeasurementBloc();
  });

  Future<void> pumpPage(WidgetTester tester, MeasurementLoaded state) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    when(() => bloc.state).thenReturn(state);
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<MeasurementBloc>.value(value: bloc, child: const MeasurementsPage()),
    ));
    await tester.pump();
  }

  testWidgets('bekleyen ölçüm işaretlidir; iki bekleyen de ayrı anahtarla çizilir', (tester) async {
    final Measurement pending2 = Measurement(weight: 69.5, createdAt: DateTime(2026, 9, 18, 10), queueKey: 'q2');
    await pumpPage(tester, MeasurementLoaded(measurements: <Measurement>[pending2, pending, saved]));

    expect(find.text('Bekliyor'), findsNWidgets(2));
    expect(find.byKey(const Key('q1')), findsOneWidget);
    expect(find.byKey(const Key('q2')), findsOneWidget);
    expect(find.byKey(const Key('m_8')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bekleyen ölçüm kaydırılınca kuyruktan çıkar, sunucuya silme gitmez', (tester) async {
    await pumpPage(tester, MeasurementLoaded(measurements: <Measurement>[pending, saved]));

    await tester.drag(find.byKey(const Key('q1')), const Offset(-900, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    verify(() => bloc.add(const DiscardPendingMeasurement('q1'))).called(1);
    verifyNever(() => bloc.add(any(that: isA<DeleteMeasurement>())));
  });

  testWidgets('seçim kipinde bekleyen ölçüme dokunmak seçmez (paylaşım internet ister)', (tester) async {
    await pumpPage(tester, MeasurementLoaded(measurements: <Measurement>[pending, saved], isSelectionMode: true));

    await tester.tap(find.text('Bekliyor'));
    await tester.pump();

    verifyNever(() => bloc.add(any(that: isA<ToggleMeasurementSelection>())));
  });
}
