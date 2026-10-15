import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_selection_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_widget_rig.dart';

SubscriptionPlan _free({bool? used}) => SubscriptionPlan(
  id: 3,
  nameAr: 'مجانية',
  nameEn: 'Free',
  descriptionAr: null,
  descriptionEn: null,
  icon: '',
  color: '',
  sortOrder: 0,
  isActive: true,
  isPopular: false,
  isFree: true,
  tier: 0,
  features: planWith().features,
  pricings: const [],
  freePlanUsed: used,
);

/// A live subscription on [plan].
CurrentSubscription _on(SubscriptionPlan plan) {
  final base = subscriptionWith();
  return CurrentSubscription(
    id: base.id,
    plan: plan,
    pricing: base.pricing,
    startsAt: base.startsAt,
    expiresAt: base.expiresAt,
    isActive: true,
    likesUsed: 0,
    likesRemaining: 50,
    photoExchangesUsed: 0,
    photoExchangesRemaining: 5,
  );
}

Widget _selection(SubscriptionPlan free, {CurrentSubscription? current}) {
  final paid = planWith(tier: 1);
  return PlanSelectionWidget(
    plans: [paid],
    activeIndex: 0,
    activePlan: paid,
    selectedPricingFor: (_) => null,
    onPlanChanged: (_) {},
    onPricingSelected: (_) {},
    resolveStoreProduct: (_) => null,
    storeResolved: true,
    freePlan: free,
    currentSub: current,
  );
}

/// TQ25 (Tariq, run 11): signed-in `/plans` marks the free plan
/// `freePlanUsed`. True: the member had it and it isn't their plan, so the
/// free card hides; false: they can activate it (or it's theirs); not sent:
/// as today. Their active free plan always shows.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  final card = find.text('Free');
  final activate = find.text(shippedSubscriptionsEn('free_activate_cta'));

  test('the model reads it; absent, null or not a bool stay null', () {
    bool? parsed(Map<String, dynamic> extra) => SubscriptionPlanModel.fromJson({
      'id': 3,
      'isFree': true,
      ...extra,
    }).toEntity().freePlanUsed;

    expect(parsed({'freePlanUsed': true}), isTrue);
    expect(parsed({'freePlanUsed': false}), isFalse);
    expect(parsed({}), isNull);
    expect(parsed({'freePlanUsed': null}), isNull);
    expect(parsed({'freePlanUsed': 'yes'}), isNull);
  });

  testWidgets('used before, not theirs now: no free card', (tester) async {
    await pumpSubscriptionWidget(tester, _selection(_free(used: true)));

    expect(card, findsNothing);
    expect(activate, findsNothing);
  });

  for (final used in const [false, null]) {
    testWidgets('freePlanUsed $used: the card, with Activate', (tester) async {
      await pumpSubscriptionWidget(tester, _selection(_free(used: used)));

      expect(card, findsOneWidget);
      expect(activate, findsOneWidget);
    });
  }

  testWidgets('their active free plan shows, whatever the flag says', (
    tester,
  ) async {
    final free = _free(used: true);
    await pumpSubscriptionWidget(tester, _selection(free, current: _on(free)));

    expect(card, findsOneWidget);
    expect(
      find.text(shippedSubscriptionsEn('badge_you_are_here')),
      findsOneWidget,
    );
    expect(activate, findsNothing);
  });
}
