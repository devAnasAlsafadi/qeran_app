import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/connectivity/connectivity_cubit.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/routes/app_router.dart';
import 'package:qeran/core/routes/route_fallback_screen.dart';
import 'package:qeran/core/routes/route_name.dart';

import '../../features/community/fixtures/community_mock_harness.dart';
import '../shipped_fonts_rig.dart';
import '../shipped_strings_rig.dart';

/// Cleanup audit `19`, run 11: a route the router doesn't know, or one that
/// came without its arguments, shows «حدث خطأ، حاول مرة أخرى» with the way
/// back, in the member's language; never "No route defined for …".
void main() {
  setUpAll(initShippedStrings);

  Future<void> open(
    WidgetTester tester,
    String lang,
    RouteSettings settings,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await pumpShippedStrings(
      tester,
      Locale(lang),
      navigatorKey: navigator,
      // As the app provides it above every route.
      builder: (_, child) => BlocProvider(
        create: (_) => ConnectivityCubit(service: FakeConnectivity()),
        child: child!,
      ),
    );
    navigator.currentState!.push(AppRouter().onGenerateRoute(settings));
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: an unknown route', (tester) async {
      await open(tester, lang, const RouteSettings(name: '/no-such-screen'));

      expect(find.byType(RouteFallbackScreen), findsOneWidget);
      expect(find.text(shipped(lang, 'errors.generic')), findsOneWidget);
      expect(find.textContaining('route'), findsNothing);

      await tester.tap(find.byType(QeranBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(RouteFallbackScreen), findsNothing);
    });
  }

  testWidgets('a known route without its arguments', (tester) async {
    await open(
      tester,
      'ar',
      const RouteSettings(name: RouteNames.matchmakerInterests),
    );

    expect(find.byType(RouteFallbackScreen), findsOneWidget);
    expect(find.text(shipped('ar', 'errors.generic')), findsOneWidget);
    expect(find.textContaining('Missing'), findsNothing);
  });
}
