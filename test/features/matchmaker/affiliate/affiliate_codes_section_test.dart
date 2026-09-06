import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_code.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_commission_type.dart';
import 'package:qeran/features/matchmaker/affiliate/presentation/widgets/affiliate_codes_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the REAL `ar.json`, unlike the key-loader used by the copy suites.
/// These assertions turn on `{percent}` and `{count}` actually interpolating —
/// a loader that echoes keys would leave the placeholders unexpanded and the
/// digit checks below would pass or fail for the wrong reason.
class _RealArabicLoader extends AssetLoader {
  const _RealArabicLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      jsonDecode(File('assets/translations/ar.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// The two numbers on a code's row belong to different people, and the row is
/// the last place that distinction can be lost.
///
/// `MQ` takes 50% off the BUYER's price and earns the matchmaker 10% — on
/// today's live data, $6.59. Rendering the 50 where the money goes would
/// overstate her income fivefold, and it would look entirely plausible.
///
/// So the assertions are about WHICH widget holds WHICH value, never about a
/// string appearing somewhere on screen.
AffiliateCode code({
  required String name,
  bool isPrimary = false,
  double discountPercent = 50,
  double commissionRate = 10,
  int used = 2,
  double earned = 6.59,
}) =>
    AffiliateCode(
      code: name,
      isPrimary: isPrimary,
      discountPercent: discountPercent,
      commissionRate: commissionRate,
      codeUsedCount: used,
      totalCommission: earned,
    );

Widget host(List<AffiliateCode> codes, {double? accountRate = 10}) =>
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'unused',
      assetLoader: const _RealArabicLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: AffiliateCodesSection(
              codes: codes,
              accountRate: accountRate,
              commissionType: AffiliateCommissionType.percent,
              currency: 'USD',
            ),
          ),
        ),
      ),
    );

String textAt(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data ?? '';

String allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' | ');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('the buyer discount and the earnings never trade places', () {
    testWidgets('the earnings slot holds the commission, with currency', (
      tester,
    ) async {
      await tester.pumpWidget(host([code(name: 'MQ')]));
      await tester.pumpAndSettle();

      final earned = textAt(tester, 'affiliate-code-earned-MQ');
      expect(
        earned,
        contains('6.59'),
        reason: 'this slot is the matchmaker money — a swap puts the buyer '
            'discount here and overstates her income fivefold',
      );
      expect(earned, contains('USD'));
      expect(
        earned,
        isNot(contains('50')),
        reason: 'the buyer discount must never appear where the money is',
      );
    });

    testWidgets('the discount is its own widget and carries no currency', (
      tester,
    ) async {
      await tester.pumpWidget(host([code(name: 'MQ')]));
      await tester.pumpAndSettle();

      final discount = textAt(tester, 'affiliate-code-discount-MQ');
      expect(discount, contains('50'));
      expect(
        discount,
        isNot(contains('USD')),
        reason: 'a percentage beside a currency reads as an amount earned',
      );
      expect(
        discount,
        isNot(contains('6.59')),
        reason: 'two facts, two widgets — merging them is how the trap returns',
      );
    });
  });

  group('a row states only what the payload can back', () {
    testWidgets('no pending or paid figure is invented per code', (
      tester,
    ) async {
      // Settlement is one account-level payout with no per-referral record, so
      // any per-code pending or paid number would be made up.
      await tester.pumpWidget(
        host([code(name: 'MQ', earned: 6.59), code(name: 'ANAS', earned: 3.68)]),
      );
      await tester.pumpAndSettle();

      final shown = allText(tester);
      expect(shown, contains('6.59'));
      expect(shown, contains('3.68'));
      expect(
        shown,
        isNot(contains('10.27')),
        reason: 'the account total belongs to the tiles above, not to a row',
      );
    });

    testWidgets('each row carries its own earnings', (tester) async {
      await tester.pumpWidget(
        host([
          code(name: 'ANAS', used: 1, earned: 3.68, isPrimary: true),
          code(name: 'MQ', used: 2, earned: 6.59),
        ]),
      );
      await tester.pumpAndSettle();

      expect(textAt(tester, 'affiliate-code-earned-ANAS'), contains('3.68'));
      expect(textAt(tester, 'affiliate-code-earned-MQ'), contains('6.59'));
    });
  });

  group('the per-code rate appears only when it says something', () {
    testWidgets('equal to the account rate — not shown', (tester) async {
      await tester.pumpWidget(
        host([code(name: 'MQ', commissionRate: 10)], accountRate: 10),
      );
      await tester.pumpAndSettle();

      expect(
        allText(tester),
        isNot(contains('10%')),
        reason: 'repeating the headline rate on every row says nothing and '
            'competes with the buyer discount beside it',
      );
    });

    testWidgets('an override — shown', (tester) async {
      await tester.pumpWidget(
        host([code(name: 'MQ', commissionRate: 15)], accountRate: 10),
      );
      await tester.pumpAndSettle();

      expect(allText(tester), contains('15%'));
    });
  });

  group('an empty list renders nothing at all', () {
    testWidgets('populated first — otherwise the check below is vacuous', (
      tester,
    ) async {
      await tester.pumpWidget(host([code(name: 'MQ')]));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('affiliate-code-earned-MQ')),
        findsOneWidget,
        reason: 'precondition: the section DOES render rows when it has any, '
            'so findsNothing below means "hidden", not "broken"',
      );
    });

    testWidgets('empty — no title, no row, no divider', (tester) async {
      await tester.pumpWidget(host(const []));
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);
    });
  });
}
