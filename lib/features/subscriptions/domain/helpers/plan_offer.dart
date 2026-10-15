import '../entities/current_subscription.dart';
import '../entities/subscription_plan.dart';
import '../entities/subscription_pricing.dart';

/// What the plans list offers a member, given the plan they hold (run 11,
/// Anas): no plan below theirs; «ترقية متاحة» only above it; their own plan
/// and period marked «باقتك الحالية», never preselected, so the member on the
/// top plan sees the period they can still take instead of a dead end.
class PlanOffer {
  PlanOffer(List<SubscriptionPlan> paidPlans, {this.owned})
    : plans = [
        for (final plan in paidPlans)
          if (!_below(plan, owned)) plan,
      ];

  /// The member's live subscription (free or paid), or null.
  final CurrentSubscription? owned;

  /// The paid plans to list, in the server's order, lower tiers left out.
  final List<SubscriptionPlan> plans;

  bool isOwnedPlan(SubscriptionPlan plan) => plan.id == owned?.plan.id;

  bool isOwnedPricing(SubscriptionPricing? pricing) =>
      pricing != null && pricing.id == owned?.pricing.id;

  /// A plan above the one they hold.
  bool isUpgrade(SubscriptionPlan plan) {
    final ownedTier = owned?.plan.tier;
    final tier = plan.tier;
    return ownedTier != null && tier != null && tier > ownedTier;
  }

  /// The plan selected on opening: the first one above theirs, else their
  /// own (for the period they don't hold), else the first.
  int get initialIndex {
    final above = plans.indexWhere(isUpgrade);
    if (above != -1) return above;
    final own = plans.indexWhere(isOwnedPlan);
    return own == -1 ? 0 : own;
  }

  /// [selected], unless it is the period they hold and they didn't [picked]
  /// it themselves: then the plan's first other period, when it has one.
  SubscriptionPricing? preselect(
    SubscriptionPlan plan,
    SubscriptionPricing? selected, {
    required bool picked,
  }) {
    if (picked || !isOwnedPricing(selected)) return selected;
    for (final pricing in plan.activePricings) {
      if (!isOwnedPricing(pricing)) return pricing;
    }
    return selected;
  }

  static bool _below(SubscriptionPlan plan, CurrentSubscription? owned) {
    final ownedTier = owned?.plan.tier;
    final tier = plan.tier;
    return ownedTier != null && tier != null && tier < ownedTier;
  }
}
