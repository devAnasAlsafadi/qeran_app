import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/services/firebase_initialization_service.dart';
import 'package:qeran/core/widgets/privacy_shield_suppression.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/splash/presentation/blocs/splash_cubit.dart';
import 'package:qeran/features/splash/presentation/blocs/splash_state.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen.dart';

/// The other half of the shield fix. `app_lifecycle_privacy_shield_test.dart`
/// proves the shield HONOURS the signal; this proves the splash actually raises
/// it — and, the part that matters for privacy, that it puts it back down.

class _MockSession extends Mock implements UserSessionCubit {}

class _MockFirebase extends Mock implements FirebaseInitializationService {}

class _StubSplashCubit extends Cubit<SplashState> implements SplashCubit {
  _StubSplashCubit() : super(SplashInitial());

  /// The screen awaits this; it must resolve without reaching storage.
  @override
  Future<void> checkAuthStatus() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Widget _host() => MaterialApp(
  home: BlocProvider<SplashCubit>(
    create: (_) => _StubSplashCubit(),
    child: const SplashScreen(),
  ),
);

void main() {
  late _MockSession session;
  late _MockFirebase firebase;

  setUp(() {
    session = _MockSession();
    firebase = _MockFirebase();
    when(() => session.hydrate()).thenAnswer((_) async {});
    when(() => session.state).thenReturn(const UserSessionUnauthenticated());
    when(() => firebase.ready).thenAnswer((_) async {});
    sl.registerFactory<UserSessionCubit>(() => session);
    sl.registerFactory<FirebaseInitializationService>(() => firebase);
    privacyShieldSuppressed.value = false;
  });

  tearDown(() async {
    await sl.reset();
    privacyShieldSuppressed.value = false;
  });

  testWidgets('raises the signal as soon as the splash is on screen', (
    tester,
  ) async {
    await tester.pumpWidget(_host());

    // Must be up BEFORE the first-launch permission alert can fire — that
    // alert is what takes the app out of `resumed` and paints the fill.
    expect(privacyShieldSuppressed.value, isTrue);
  });

  testWidgets('puts the signal back down when the splash leaves', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(privacyShieldSuppressed.value, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    // The security-critical half: leaving it raised would unshield every
    // screen that follows — photos, chats, the whole profile.
    expect(privacyShieldSuppressed.value, isFalse);
  });
}
