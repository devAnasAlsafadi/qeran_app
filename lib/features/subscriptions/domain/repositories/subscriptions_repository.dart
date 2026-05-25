import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../entities/discount_validation.dart';
import '../entities/subscription_plan.dart';

abstract interface class SubscriptionsRepository {
  /// Dashboard-defined plans. Returns `Right([])` for empty server data,
  /// `Left(ServerFailure)` for transport / parsing errors.
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();

  /// Current subscription, or `Right(null)` when the user has none.
  Future<Either<Failure, CurrentSubscription?>> getCurrent();

  /// Validates [code] against the selected [pricingId]. Invalid codes
  /// arrive as `Right(DiscountValidation(isValid: false, ...))` — only
  /// network / parsing failures surface as `Left`.
  Future<Either<Failure, DiscountValidation>> validateDiscount({
    required String code,
    required int pricingId,
  });

  /// Subscribe to the given [pricingId] with an optional [discountCode].
  /// Returns the new `CurrentSubscription` on success.
  Future<Either<Failure, CurrentSubscription>> subscribe({
    required int pricingId,
    String? discountCode,
  });
}
