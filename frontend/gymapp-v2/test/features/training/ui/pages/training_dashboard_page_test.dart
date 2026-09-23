import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_bloc.dart';
import 'package:gymapp_v2/features/training/bloc/training_event.dart';
import 'package:gymapp_v2/features/training/bloc/training_state.dart';
import 'package:gymapp_v2/features/training/models/training_models.dart';
import 'package:gymapp_v2/features/training/ui/pages/training_dashboard_page.dart';
import 'package:mocktail/mocktail.dart';

class MockTrainingBloc extends MockBloc<TrainingEvent, TrainingState> implements TrainingBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

/// Kişisel program listesi, internetsiz değişiklikler (G-74).
void main() {
  late MockTrainingBloc trainingBloc;
  late MockAuthBloc authBloc;

  TrainingBlock program({required int id, required String name, String? localId, bool isQueued = false}) =>
      TrainingBlock(
        id: id,
        name: name,
        coachName: 'Kişisel Program',
        clientId: 0,
        clientName: '',
        startDate: DateTime(2026, 9, 23),
        endDate: DateTime(2026, 10, 21),
        isActive: false,
        isPersonal: true,
        workoutDays: const <WorkoutDay>[],
        localId: localId,
        isQueued: isQueued,
      );

  setUpAll(() {
    registerFallbackValue(const LoadMyPrograms());
  });

  setUp(() {
    trainingBloc = MockTrainingBloc();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthInitial());
    when(() => trainingBloc.state).thenReturn(
      TrainingState(
        status: TrainingStatus.success,
        activePrograms: <TrainingBlock>[
          program(id: 0, name: 'Yerel Program', localId: 'L1', isQueued: true),
          program(id: 5, name: 'Sunucudaki Program'),
        ],
      ),
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<TrainingBloc>.value(value: trainingBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(home: TrainingDashboardPage()),
      ),
    );
    await tester.pump();
  }

  testWidgets('sunucuya gitmemiş program BEKLİYOR işaretlidir ve etkinleştirilemez', (WidgetTester tester) async {
    await pumpPage(tester);

    expect(find.text('BEKLİYOR'), findsOneWidget);
    // Yalnızca sunucudaki programda: bekleyen programın sunucu kimliği yok.
    expect(find.text('AKTİF ET'), findsOneWidget);
  });

  testWidgets('bekleyen programın silinmesi cihaz kimliğiyle istenir', (WidgetTester tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pump();
    await tester.tap(find.text('SİL'));
    await tester.pump();

    verify(() => trainingBloc.add(const DeleteProgram(0, localId: 'L1'))).called(1);
  });
}
