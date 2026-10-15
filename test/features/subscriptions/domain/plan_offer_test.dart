import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/helpers/plan_offer.dart';

import '../presentation/widgets/plans_store_rig.dart';
import '../top_plan_fixtures.dart';

PlanOffer _offer(CurrentSubscription? owned) =>
    PlanOffer([basic, vip], owned: owned);

/// Run 11 (Anas): what the plans list offers each member. No plan below
/// theirs; «ترقية متاحة» only above it; their plan and period «باقتك
/// الحالية», never preselected.
void main() {
  test('VIP monthly: VIP alone, the 3 months preselected', () {
    final offer = _offer(vipMonthly);

    expect(offer.plans, [vip]);
    expect(offer.initialIndex, 0);
    expect(offer.preselect(vip, vipMonth, picked: false), vipQuarter);
    expect(offer.isOwnedPlan(vip), isTrue);
    expect(offer.isUpgrade(vip), isFalse);
  });

  test('VIP 3 months: the month preselected', () {
    final offer = _offer(vipQuarterly);

    expect(offer.plans, [vip]);
    expect(offer.preselect(vip, vipQuarter, picked: false), vipMonth);
    expect(offer.preselect(vip, vipMonth, picked: false), vipMonth);
  });

  test('their own period stays when they picked it', () {
    final offer = _offer(vipMonthly);

    expect(offer.preselect(vip, vipMonth, picked: true), vipMonth);
    expect(offer.isOwnedPricing(vipMonth), isTrue);
    expect(offer.isOwnedPricing(vipQuarter), isFalse);
  });

  test('Basic: Basic and VIP, VIP preselected and the upgrade', () {
    final offer = _offer(basicMonthly);

    expect(offer.plans, [basic, vip]);
    expect(offer.initialIndex, 1);
    expect(offer.isUpgrade(vip), isTrue);
    expect(offer.isUpgrade(basic), isFalse);
    // One period only: nothing else to preselect.
    expect(offer.preselect(basic, basicMonth, picked: false), basicMonth);
  });

  test('Free: every paid plan, each an upgrade, the first preselected', () {
    final offer = _offer(freeTrial);

    expect(offer.plans, [basic, vip]);
    expect(offer.initialIndex, 0);
    expect(offer.isUpgrade(basic), isTrue);
    expect(offer.isUpgrade(vip), isTrue);
  });

  test('a manual grant: the same offer as the plan it grants', () {
    final granted = _offer(manualGrant);
    final bought = _offer(vipMonthly);

    expect(granted.plans, bought.plans);
    expect(granted.initialIndex, bought.initialIndex);
    expect(
      granted.preselect(vip, vipMonth, picked: false),
      bought.preselect(vip, vipMonth, picked: false),
    );
  });

  test('none: every paid plan, no upgrade, nothing owned', () {
    final offer = _offer(null);

    expect(offer.plans, [basic, vip]);
    expect(offer.initialIndex, 0);
    expect(offer.isUpgrade(vip), isFalse);
    expect(offer.isOwnedPricing(vipMonth), isFalse);
    expect(offer.preselect(vip, vipQuarter, picked: false), vipQuarter);
  });

  test('a plan without a tier is neither hidden nor an upgrade', () {
    final untiered = planOf(id: 9, tier: null);
    final offer = PlanOffer([untiered, vip], owned: vipMonthly);

    expect(offer.plans, [untiered, vip]);
    expect(offer.isUpgrade(untiered), isFalse);
  });
}
