import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/data/models/subscription_plan_model.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import 'plans_store_rig.dart';

/// Run 10, plans item 4: «الأكثر طلباً» goes by the plan's `isPopular` (it
/// went by the VIP tier), until Tariq sends `badgeAr` / `badgeEn` (TQ20);
/// then by those, and null means no badge.
void main() {
  setUpAll(() async {
    await loadShippedFonts();
    await initShippedStrings();
  });

  final popularAr = find.text('الأكثر طلباً');

  testWidgets('isPopular: the badge, in both languages', (tester) async {
    await pumpPlans(tester, const Locale('ar'));
    expect(popularAr, findsOneWidget);
  });

  testWidgets('English: the same', (tester) async {
    await pumpPlans(tester, const Locale('en'));
    expect(find.text('Popular'), findsOneWidget);
  });

  testWidgets('VIP but not popular: no badge', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [planOf(isPopular: false)],
    );
    expect(popularAr, findsNothing);
  });

  testWidgets('popular Basic: the badge', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [planOf(tier: 1, nameAr: 'الباقة الأساسية')],
    );
    expect(popularAr, findsOneWidget);
  });

  testWidgets('the dashboard\'s badge, once sent, wins', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [
        planOf(hasBadgeFields: true, badgeAr: 'الأوفر', badgeEn: 'Best value'),
      ],
    );
    expect(find.text('الأوفر'), findsOneWidget);
    expect(popularAr, findsNothing);
  });

  testWidgets('sent as null: no badge, even when popular', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [planOf(hasBadgeFields: true)],
    );
    expect(popularAr, findsNothing);
  });

  testWidgets('a long name with its badge wraps, never overflows', (
    tester,
  ) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [planOf(nameAr: 'الباقة الذهبية الممتازة للأعضاء المميزين جداً')],
    );
    expect(popularAr, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the model: badge fields present or not', () {
    final before = SubscriptionPlanModel.fromJson({'isPopular': true});
    expect(before.toEntity().hasBadgeFields, isFalse);
    final after = SubscriptionPlanModel.fromJson({
      'badgeAr': 'الأوفر',
      'badgeEn': null,
    }).toEntity();
    expect(after.hasBadgeFields, isTrue);
    expect(after.badge(isArabic: false), 'الأوفر');
  });
}
