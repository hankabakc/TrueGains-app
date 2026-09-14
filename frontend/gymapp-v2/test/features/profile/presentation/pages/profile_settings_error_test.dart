import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp_v2/features/auth/data/models/user_role.dart';
import 'package:gymapp_v2/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_event.dart';
import 'package:gymapp_v2/features/profile/presentation/bloc/profile_state.dart';
import 'package:gymapp_v2/features/profile/presentation/pages/profile_settings_page.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockProfileBloc profileBloc;
  late MockAuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const FetchProfile());
  });

  setUp(() {
    profileBloc = MockProfileBloc();
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(AuthInitial());
  });

  testWidgets('hata durumunda snackbar gösterilir ve profil kurtarmak için FetchProfile tetiklenir', (tester) async {
    when(() => profileBloc.state).thenReturn(const ProfileError('Sunucu hatası'));
    whenListen(
      profileBloc,
      Stream.fromIterable([const ProfileError('Sunucu hatası')]),
      initialState: const ProfileError('Sunucu hatası'),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileBloc>.value(value: profileBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MaterialApp(
          home: ProfileSettingsPage(role: UserRole.CLIENT, userId: 1),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sunucu hatası'), findsOneWidget);
    verify(() => profileBloc.add(any(that: isA<FetchProfile>()))).called(1);
  });
}
