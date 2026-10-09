import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:qeran/features/onboarding/presentation/screens/on_boarding_screen.dart';
import 'package:qeran/features/onboarding/presentation/widgets/custom_dot_indicator.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_community_frame.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_mediation_frame.dart';
import 'package:qeran/features/onboarding/presentation/widgets/frames/onboarding_roadmap_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockStorage extends Mock implements StorageService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

late SharedPreferences _prefs;

/// The screen in Arabic on the board's phone; named routes answer with their
/// name, so where onboarding leads can be read off the screen.
Future<void> _pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpShippedStrings(
    tester,
    const Locale('ar'),
    child: const OnBoardingScreen(),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Text('route ${settings.name}'),
    ),
  );
}

/// The page in view: the one whose left edge is the screen's.
bool _inView(WidgetTester tester, Type frame) =>
    tester.getRect(find.byType(frame)).left == 0;

Future<void> _tapNextOn(WidgetTester tester, Type frame) async {
  await tester.tap(
    find.descendant(of: find.byType(frame), matching: find.text('التالي')),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initShippedStrings);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
    sl.registerFactory<OnboardingCubit>(
      () => OnboardingCubit(sharedPref: SharedPrefService(_prefs)),
    );
    sl.registerLazySingleton<UserSessionCubit>(
      () => UserSessionCubit(
        secureStorage: _MockStorage(),
        sharedPrefs: SharedPrefService(_prefs),
        googleSignIn: _MockGoogleSignIn(),
      ),
    );
  });

  tearDown(sl.reset);

  testWidgets('opens on the community slide, the first of three dots', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(_inView(tester, OnboardingCommunityFrame), isTrue);
    final dots = tester.widget<CustomDotIndicator>(
      find.descendant(
        of: find.byType(OnboardingCommunityFrame),
        matching: find.byType(CustomDotIndicator),
      ),
    );
    expect(dots.count, 3);
    expect(dots.activeIndex, 0);
  });

  testWidgets('«التالي» walks on to the mediation slide, then the roadmap', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await _tapNextOn(tester, OnboardingCommunityFrame);
    expect(_inView(tester, OnboardingMediationFrame), isTrue);

    await _tapNextOn(tester, OnboardingMediationFrame);
    expect(_inView(tester, OnboardingRoadmapFrame), isTrue);
  });

  testWidgets('skip on the first slide finishes onboarding and opens login', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('تخطّي'));
    await tester.pumpAndSettle();

    expect(_prefs.getBool(StorageKeys.seenOnboarding), isTrue);
    expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
  });
}
