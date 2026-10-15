import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/presentation/screens/purchase_success_screen.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/my_subscription_card.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_features_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_widget_rig.dart';

/// Serious interests are unused and nothing spends them (Tariq, TQ26, run
/// 11): no member screen draws them, even while the server still sends the
/// fields (until launch day), and every other row stays.
void main() {
  final likes = shippedSubscriptionsEn('feature_likes_label');
  final serious = find.textContaining('erious');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  void expectNoRow() {
    expect(serious, findsNothing);
    expect(find.byIcon(Icons.handshake_rounded), findsNothing);
    expect(find.text(likes), findsOneWidget);
  }

  testWidgets('plan card checklist: no row while the allowance is sent', (
    tester,
  ) async {
    await pumpSubscriptionWidget(
      tester,
      PlanFeaturesWidget(plan: planWith(seriousInterests: -1)),
    );

    expectNoRow();
  });

  testWidgets('«اشتراكي»: no row while all three counters are sent', (
    tester,
  ) async {
    await pumpSubscriptionWidget(
      tester,
      MySubscriptionCard(
        subscription: subscriptionWith(allowed: -1, used: 0, remaining: -1),
        expiring: false,
      ),
    );

    expectNoRow();
  });

  testWidgets('purchase success: no row while the allowance is sent', (
    tester,
  ) async {
    await pumpSubscriptionWidget(
      tester,
      PurchaseSuccessScreen(plan: planWith(seriousInterests: 3)),
      page: true,
    );

    expectNoRow();
  });
}
