import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../repositories/subscriptions_repository.dart';

// TODO(payments-1b): reserved. After a successful RevenueCat purchase the client POSTs /subscriptions/subscribe to record the entitlement; the backend applies discount/affiliate codes server-side.
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
