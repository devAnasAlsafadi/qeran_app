import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// The paywall sheet a gated action raises: its copy per intent and per
/// subscription, and its two buttons. Pinned before C5 adds its "activating"
/// variant and splits the sheet's long build.
void main() {
  setUpAll(initShippedStrings);

  late _MockCurrent current;
  late List<String> routes;

  setUp(() {
    current = _MockCurrent();
    routes = [];
    when(() => current.state).thenReturn(const CurrentSubscriptionNone());
    when(() => current.stream).thenAnswer((_) => const Stream.empty());
    when(() => current.hasActiveSubscription).thenReturn(false);
  });

  Future<void> open(WidgetTester tester, PaywallIntent intent) async {
    final context = await pumpShippedStrings(
      tester,
      const Locale('en'),
      builder: (_, child) => BlocProvider<CurrentSubscriptionCubit>.value(
        value: current,
        child: child!,
      ),
      onGenerateRoute: (settings) {
        routes.add(settings.name!);
        return MaterialPageRoute<void>(builder: (_) => const Scaffold());
      },
    );
    showPaywall(context, intent: intent);
    await tester.pumpAndSettle();
  }

  testWidgets('a like without a subscription: the like copy, View packages', (
    tester,
  ) async {
    await open(tester, PaywallIntent.like);

    expect(find.text('Subscribe to show interest'), findsOneWidget);
    expect(find.text('View packages'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('a like with a subscription: used up, Upgrade', (tester) async {
    when(() => current.hasActiveSubscription).thenReturn(true);

    await open(tester, PaywallIntent.like);

    expect(find.text('No interests left'), findsOneWidget);
    expect(find.text('Upgrade subscription'), findsOneWidget);
  });

  testWidgets('photo exchange has its own copy', (tester) async {
    await open(tester, PaywallIntent.photoExchange);

    expect(find.text('Photo exchange is for subscribers'), findsOneWidget);
  });

  testWidgets('Not now closes the sheet, nothing opened', (tester) async {
    await open(tester, PaywallIntent.like);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('View packages'), findsNothing);
    expect(routes, isEmpty);
  });

  testWidgets('the main button closes the sheet and opens the plans', (
    tester,
  ) async {
    await open(tester, PaywallIntent.like);

    await tester.tap(find.text('View packages'));
    await tester.pumpAndSettle();

    expect(find.text('Not now'), findsNothing);
    expect(routes, [RouteNames.packagesScreen]);
  });
}
