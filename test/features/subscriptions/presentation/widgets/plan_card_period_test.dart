import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/price_period.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import 'plans_store_rig.dart';

/// Run 10, plans item 1: the card's price line said «/شهر» after every price,
/// so VIP's three-month price read as monthly. The period now comes from the
/// store's `subscriptionPeriod`, else the dashboard's period label.
void main() {
  setUpAll(() async {
    await loadShippedFonts();
    await initShippedStrings();
  });

  final month = productOf('qeran_vip_monthly', 'SAR 34.99', period: 'P1M');
  final quarter = productOf('qeran_vip_3month', 'SAR 99.99', period: 'P3M');
  final products = {month.identifier: month, quarter.identifier: quarter};

  testWidgets('Arabic: three months read as three months', (tester) async {
    await pumpPlans(tester, const Locale('ar'), products: products);

    expect(find.text('SAR 99.99 / 3 أشهر'), findsOneWidget);
    expect(find.textContaining('/شهر'), findsNothing);
  });

  testWidgets('Arabic: one month reads «شهر»', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      products: products,
      selected: vipMonth,
    );

    expect(find.text('SAR 34.99 / شهر'), findsOneWidget);
  });

  testWidgets('English: the same', (tester) async {
    await pumpPlans(tester, const Locale('en'), products: products);
    expect(find.text('SAR 99.99 / 3 months'), findsOneWidget);
    expect(find.textContaining('/mo'), findsNothing);
  });

  testWidgets('no store period: the dashboard\'s label', (tester) async {
    final bare = productOf('qeran_vip_3month', 'SAR 99.99');
    await pumpPlans(
      tester,
      const Locale('ar'),
      products: {bare.identifier: bare},
    );

    expect(find.text('SAR 99.99 / 3 شهور'), findsOneWidget);
  });

  testWidgets('every unit, ar', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    const cases = {
      'P1D': 'يوم',
      'P1W': 'أسبوع',
      'P2M': 'شهرين',
      'P6M': '6 أشهر',
      'P11M': '11 شهراً',
      'P1Y': 'سنة',
    };
    cases.forEach((iso, words) {
      final product = productOf('x', 'SAR 1', period: iso);
      expect(pricePeriod(context, vipMonth, product), words, reason: iso);
    });
  });

  testWidgets('every unit, en', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    const cases = {
      'P1D': 'day',
      'P1W': 'week',
      'P2M': '2 months',
      'P6M': '6 months',
      'P11M': '11 months',
      'P1Y': 'year',
    };
    cases.forEach((iso, words) {
      final product = productOf('x', 'SAR 1', period: iso);
      expect(pricePeriod(context, vipMonth, product), words, reason: iso);
    });
  });

  testWidgets('no period anywhere: its days', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    final unlabelled = pricingOf(id: 1, days: 90);

    expect(pricePeriod(context, unlabelled, null), '90 يوم');
  });
}
