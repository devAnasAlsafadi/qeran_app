import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../repositories/subscriptions_repository.dart';

/// Free-tier subscription only (`isFree` plan / final price 0 / 100% code).
/// Paid subscriptions activate via RevenueCat + the server-side webhook,
/// **not** this endpoint — the backend rejects a paid tier here
/// («هذا الاشتراك مدفوع ويُفعَّل عبر المتجر»).
/// See docs/PAYWALL_IMPLEMENTATION_PLAN.md §2.6.
class SubscribeUseCase {
  final SubscriptionsRepository _repository;
  const SubscribeUseCase(this._repository);

  /// **Important:** [pricingId] — never `planId`. The backend ties
  /// duration + price to the pricing row, not the plan.
  Future<Either<Failure, CurrentSubscription>> call({
    required int pricingId,
    String? discountCode,
  }) =>
      _repository.subscribe(pricingId: pricingId, discountCode: discountCode);
}
