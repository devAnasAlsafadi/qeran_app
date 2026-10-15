import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/my_subscription_card.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import '../../top_plan_fixtures.dart';

/// Run 11: «ترقية الاشتراك» on «اشتراكي» opens the plans screen for every
/// member, the top plan included — where the list now shows the period they
/// don't hold instead of a celebration.
void main() {
  setUpAll(initShippedStrings);

  for (final (name, held) in [
    ('VIP monthly', vipMonthly),
    ('VIP 3 months', vipQuarterly),
    ('Basic', basicMonthly),
  ]) {
    testWidgets('$name: «ترقية الاشتراك» opens the plans', (tester) async {
      final opened = <String?>[];
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpShippedStrings(
        tester,
        const Locale('ar'),
        child: SingleChildScrollView(
          child: MySubscriptionCard(subscription: held, expiring: false),
        ),
        onGenerateRoute: (settings) {
          opened.add(settings.name);
          return MaterialPageRoute(builder: (_) => const SizedBox());
        },
      );

      await tester.tap(find.text(shipped('ar', 'subscriptions.upgrade_cta')));
      await tester.pumpAndSettle();

      expect(opened, [RouteNames.packagesScreen]);
    });
  }
}
