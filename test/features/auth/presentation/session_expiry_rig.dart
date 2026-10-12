import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/routes/app_route_tracker.dart';
import 'package:qeran/core/session/session_expiry.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/session_expiry_handler.dart';

import '../../../core/memory_storage.dart';
import '../../../core/shipped_strings_rig.dart';

class _MockSession extends Mock implements UserSessionCubit {}

/// What the member reads when the session ends, in English.
const expiredNotice = 'Session expired. Please log in again.';

/// The app around a [SessionExpiryHandler]: signed in as `jwt-1`, every
/// screen a route named on it, its sign-outs counted in [signOuts].
class ExpiryRig {
  ExpiryRig() {
    when(() => session.expireSession()).thenAnswer((_) async {
      signOuts++;
      // The secure store takes a moment to drop the token, as on the phone:
      // the window in which the other reports still find it stored.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await secure.remove(StorageKeys.token);
    });
  }

  final secure = MemoryStorage()..values[StorageKeys.token] = 'jwt-1';
  final session = _MockSession();
  final expiry = SessionExpiry();
  final routes = AppRouteTracker();
  final navigator = GlobalKey<NavigatorState>();
  int signOuts = 0;

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
}
