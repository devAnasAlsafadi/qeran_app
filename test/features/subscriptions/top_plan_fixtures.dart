import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';

import 'presentation/widgets/plans_store_rig.dart';

/// The live catalogue's shape (run 11): Free (tier 0), Basic (tier 1, one
/// period), VIP (tier 2, a month and 3 months), and a member holding one.

final basicMonth = pricingOf(
  id: 7,
  planId: 4,
  labelAr: 'شهر',
  labelEn: 'Basic month',
  productId: 'qeran_basic_monthly',
);

final freeMonth = pricingOf(id: 1, planId: 3, price: 0);

final basic = planOf(
  id: 4,
  nameAr: 'الأساسية',
  nameEn: 'Basic',
  tier: 1,
  isPopular: false,
  pricings: [basicMonth],
);

final vip = planOf();

final free = planOf(
  id: 3,
  nameAr: 'المجانية',
  nameEn: 'Free',
  tier: 0,
  isPopular: false,
  isFree: true,
  pricings: [freeMonth],
);

/// A live subscription on [plan] at [pricing].
CurrentSubscription holding(
  SubscriptionPlan plan,
  SubscriptionPricing pricing,
) => CurrentSubscription(
  id: 7,
  plan: plan,
  pricing: pricing,
  startsAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 20)),
  isActive: true,
  likesUsed: 0,
  likesRemaining: 50,
  photoExchangesUsed: 0,
  photoExchangesRemaining: 5,
);

final vipMonthly = holding(vip, vipMonth);
final vipQuarterly = holding(vip, vipQuarter);
final basicMonthly = holding(basic, basicMonth);
final freeTrial = holding(free, freeMonth);

/// A VIP month granted by hand in the dashboard: to the plans screen it is
/// the same `/current` as a bought one; only the store knows the difference.
final manualGrant = holding(vip, vipMonth);
