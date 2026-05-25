import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../repositories/subscriptions_repository.dart';

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
