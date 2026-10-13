import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/data/models/subscription_plan_model.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import 'plans_store_rig.dart';

/// Run 10, plans item 3: the dashboard's `subtitleAr` / `subtitleEn` show
/// under each plan's name, the paid cards and the free card alike.
void main() {
  setUpAll(() async {
    await loadShippedFonts();
    await initShippedStrings();
  });

  const vipAr = 'تسريع النتائج… بمتابعة مكثفة';
  const vipEn = 'Faster results — with intensive follow-up';

  group('the model', () {
    test('parses both, carried to the plan', () {
      final plan = SubscriptionPlanModel.fromJson({
        'subtitleAr': vipAr,
        'subtitleEn': vipEn,
      }).toEntity();
      expect(plan.subtitle(isArabic: true), vipAr);
      expect(plan.subtitle(isArabic: false), vipEn);
    });

    test('the other language when this one is blank; null when both are', () {
      expect(planOf(subtitleAr: vipAr).subtitle(isArabic: false), vipAr);
      expect(planOf(subtitleEn: ' ').subtitle(isArabic: true), isNull);
    });
  });

  testWidgets('Arabic: under the paid plan\'s name', (tester) async {
    await pumpPlans(
      tester,
      const Locale('ar'),
      plans: [planOf(subtitleAr: vipAr, subtitleEn: vipEn)],
    );

    expect(find.text(vipAr), findsOneWidget);
    final name = tester.getRect(find.text('الباقة الذهبية'));
    expect(tester.getRect(find.text(vipAr)).top, greaterThan(name.bottom - 1));
  });

  testWidgets('English: the English one', (tester) async {
    await pumpPlans(
      tester,
      const Locale('en'),
      plans: [planOf(subtitleAr: vipAr, subtitleEn: vipEn)],
    );

    expect(find.text(vipEn), findsOneWidget);
    expect(find.text(vipAr), findsNothing);
  });

  testWidgets('the free card has its own', (tester) async {
    const freeAr = 'جرّب قِران شهراً مجاناً';
    await pumpPlans(
      tester,
      const Locale('ar'),
      freePlan: planOf(
        id: 3,
        nameAr: 'الباقة المجانية',
        tier: 0,
        isFree: true,
        isPopular: false,
        subtitleAr: freeAr,
        pricings: [pricingOf(id: 7, planId: 3, labelAr: 'شهر مجاني')],
      ),
    );

    expect(find.text(freeAr), findsOneWidget);
  });
}
