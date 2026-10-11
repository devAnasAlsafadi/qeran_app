import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/routes/app_route_tracker.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/session_expiry_handler.dart';

import '../../../core/memory_storage.dart';
import '../../../core/shipped_strings_rig.dart';

class _MockSession extends Mock implements UserSessionCubit {}

const _expired = 'Session expired. Please log in again.';

/// C4 (Q25, TQ11): a 401 to our Bearer signs out once, however many requests
/// fail together, and lands on login with «انتهت الجلسة», in both roles. Only
/// while the token is still the stored one, and never before the splash has
/// routed.
void main() {
  setUpAll(initShippedStrings);

  late MemoryStorage secure;
  late _MockSession session;
  late SessionExpiry expiry;
  late AppRouteTracker routes;
  late GlobalKey<NavigatorState> navigator;
  late int signOuts;

  setUp(() {
    AppSnackBar.debugReset();
    secure = MemoryStorage()..values[StorageKeys.token] = 'jwt-1';
    session = _MockSession();
    signOuts = 0;
    when(() => session.expireSession()).thenAnswer((_) async {
      signOuts++;
      // The secure store takes a moment to drop the token, as on the phone:
      // the window in which the other reports still find it stored.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await secure.remove(StorageKeys.token);
    });
    expiry = SessionExpiry();
    routes = AppRouteTracker();
    navigator = GlobalKey<NavigatorState>();
  });

  tearDown(AppSnackBar.debugReset);

  Future<void> routeTo(WidgetTester tester, String name) async {
    navigator.currentState!.pushNamedAndRemoveUntil(name, (_) => false);
    await tester.pumpAndSettle();
  }

  /// The app on its splash (`/`), or already routed to [at]. The handler
  /// starts inside the test, so its turns run in the test's clock.
  Future<void> openApp(WidgetTester tester, {String? at}) async {
    SessionExpiryHandler(
      expiry: expiry,
      session: session,
      secureStorage: secure,
      navigator: navigator,
      routes: routes,
    ).start();
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      navigatorKey: navigator,
      navigatorObservers: [routes],
      builder: (_, child) => AppSnackBarHost(child: child!),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('route ${settings.name}')),
      ),
    );
    if (at != null) await routeTo(tester, at);
  }

  /// The sign-out's turns, then the route change and the notice's entrance.
  Future<void> handled(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
  }

  /// The notice's hold and exit, so no timer outlives the test.
  Future<void> dismissed(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 5));

  for (final home in [RouteNames.homeScreen, RouteNames.matchmakerHome]) {
    testWidgets('three 401s at once: one sign-out, login on top, one notice '
        '[$home]', (tester) async {
      await openApp(tester, at: home);

      expiry
        ..report('jwt-1')
        ..report('jwt-1')
        ..report('jwt-1');
      await handled(tester);

      expect(signOuts, 1);
      expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
      expect(find.text('route $home', skipOffstage: false), findsNothing);
      expect(find.text(_expired), findsOneWidget);
      await dismissed(tester);
    });
  }

  testWidgets('a token already replaced (a new sign-in) is not this '
      'session\'s', (tester) async {
    await openApp(tester, at: RouteNames.homeScreen);
    secure.values[StorageKeys.token] = 'jwt-2';

    expiry.report('jwt-1');
    await handled(tester);

    expect(signOuts, 0);
    expect(find.text('route ${RouteNames.homeScreen}'), findsOneWidget);
  });

  testWidgets('a late 401 from the old token, after the sign-out, changes '
      'nothing', (tester) async {
    await openApp(tester, at: RouteNames.homeScreen);
    expiry.report('jwt-1');
    await handled(tester);

    expiry.report('jwt-1');
    await handled(tester);

    expect(signOuts, 1);
    await dismissed(tester);
  });

  testWidgets('on the splash, it waits for the splash to route, then signs '
      'out', (tester) async {
    await openApp(tester);

    expiry.report('jwt-1');
    await handled(tester);
    expect(signOuts, 0, reason: 'the splash has not routed yet');

    await routeTo(tester, RouteNames.homeScreen);
    await handled(tester);

    expect(signOuts, 1);
    expect(find.text('route ${RouteNames.loginScreen}'), findsOneWidget);
    await dismissed(tester);
  });
}
