import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/presentation/screens/purchase_success_screen.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/my_subscription_card.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_features_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'subscription_widget_rig.dart';

/// The backend drops the three `seriousInterests*` fields on release day. Each
/// screen that lists the allowance draws its row only while the server still
/// sends it — and draws every other row either way.
void main() {
  final label = shippedSubscriptionsEn('feature_serious_interests_label');
  final likes = shippedSubscriptionsEn('feature_likes_label');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await loadShippedFonts();
  });

  group('plan card fallback checklist', () {
    testWidgets('draws the row while the allowance is sent', (tester) async {
      await pumpSubscriptionWidget(
        tester,
        PlanFeaturesWidget(plan: planWith(seriousInterests: -1)),
      );

      expect(find.text(label), findsOneWidget);
    });

    testWidgets('omits only that row once it is absent', (tester) async {
      await pumpSubscriptionWidget(
        tester,
        PlanFeaturesWidget(plan: planWith()),
      );

      expect(find.text(label), findsNothing);
      expect(find.text(likes), findsOneWidget);
    });
  });

  group('my subscription card', () {
    testWidgets('draws the row while all three counters are sent', (
      tester,
    ) async {
      await pumpSubscriptionWidget(
        tester,
        MySubscriptionCard(
          subscription: subscriptionWith(allowed: -1, used: 0, remaining: -1),
          expiring: false,
        ),
      );

      expect(find.text(label), findsOneWidget);
    });

    testWidgets('omits only that row once they are absent', (tester) async {
      await pumpSubscriptionWidget(
        tester,
        MySubscriptionCard(subscription: subscriptionWith(), expiring: false),
      );

      expect(find.text(label), findsNothing);
      expect(find.text(likes), findsOneWidget);
    });
  });

  group('purchase success', () {
    testWidgets('draws the row while the allowance is sent', (tester) async {
      await pumpSubscriptionWidget(
        tester,
        PurchaseSuccessScreen(plan: planWith(seriousInterests: 3)),
        page: true,
      );

      expect(find.text(label), findsOneWidget);
    });

    testWidgets('omits only that row once it is absent', (tester) async {
      await pumpSubscriptionWidget(
        tester,
        PurchaseSuccessScreen(plan: planWith()),
        page: true,
      );

      expect(find.text(label), findsNothing);
      expect(find.text(likes), findsOneWidget);
    });
  });
}
