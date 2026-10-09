import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_bottom_sheet.dart';
import 'package:qeran/features/subscriptions/presentation/paywall/paywall_intent.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/subscription_status_block.dart';

import '../../../core/shipped_strings_rig.dart';

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// The shipped `subscriptions.<key>` in [lang].
String _s(String lang, String key) =>
    ((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                as Map<String, dynamic>)['subscriptions']
            as Map<String, dynamic>)[key]
        as String;

/// C5: where the app would say Free, a purchase the store confirmed says
/// "activating" — «اشتراكي» and a paywall the server raises in the gap. After
/// ten minutes, a line points to Help & support.
void main() {
  setUpAll(initShippedStrings);

  late _MockCurrent current;

  void activating({required bool overdue}) {
    when(() => current.state).thenReturn(
      CurrentSubscriptionActivating(since: DateTime.now(), overdue: overdue),
    );
  }

  setUp(() {
    current = _MockCurrent();
    when(() => current.stream).thenAnswer((_) => const Stream.empty());
    when(() => current.hasActiveSubscription).thenReturn(false);
  });

  Widget provided(Widget child) => BlocProvider<CurrentSubscriptionCubit>.value(
    value: current,
    child: child,
  );

  for (final lang in const ['ar', 'en']) {
    final locale = Locale(lang);

    testWidgets('«اشتراكي» says activating, not the no-subscription card '
        '[$lang]', (tester) async {
      activating(overdue: false);

      await pumpShippedStrings(
        tester,
        locale,
        child: provided(const SubscriptionStatusBlock()),
      );

      expect(find.text(_s(lang, 'activating_title')), findsOneWidget);
      expect(find.text(_s(lang, 'activating_body')), findsOneWidget);
      expect(find.text(_s(lang, 'activating_overdue')), findsNothing);
      expect(find.text(_s(lang, 'none_title')), findsNothing);
    });

    testWidgets('after ten minutes, the Help & support line [$lang]', (
      tester,
    ) async {
      activating(overdue: true);

      await pumpShippedStrings(
        tester,
        locale,
        child: provided(const SubscriptionStatusBlock()),
      );

      expect(find.text(_s(lang, 'activating_overdue')), findsOneWidget);
    });

    testWidgets('a paywall in the gap says activating, not the plans '
        '[$lang]', (tester) async {
      activating(overdue: true);
      final context = await pumpShippedStrings(
        tester,
        locale,
        builder: (_, child) => provided(child!),
      );

      showPaywall(context, intent: PaywallIntent.like);
      await tester.pumpAndSettle();

      expect(find.text(_s(lang, 'activating_title')), findsOneWidget);
      expect(find.text(_s(lang, 'activating_overdue')), findsOneWidget);
      expect(find.text(_s(lang, 'view_packages_cta')), findsNothing);

      await tester.tap(find.text(_s(lang, 'activating_ok')));
      await tester.pumpAndSettle();
      expect(find.text(_s(lang, 'activating_title')), findsNothing);
    });
  }
}
