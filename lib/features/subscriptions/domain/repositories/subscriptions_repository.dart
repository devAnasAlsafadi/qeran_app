import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/current_subscription.dart';
import '../entities/subscription_plan.dart';
import '../entities/validate_code_response.dart';

abstract interface class SubscriptionsRepository {
  /// Dashboard-defined plans. Returns `Right([])` for empty server data,
  /// `Left(ServerFailure)` for transport / parsing errors.
  Future<Either<Failure, List<SubscriptionPlan>>> getPlans();

  /// Current subscription, or `Right(null)` when the user has none.
  Future<Either<Failure, CurrentSubscription?>> getCurrent();

  /// Subscribe to the given [pricingId] with an optional [discountCode].
  /// Returns the new `CurrentSubscription` on success.
  Future<Either<Failure, CurrentSubscription>> subscribe({
    required int pricingId,
    String? discountCode,
  });

  /// Validates a discount code for a store product + platform. Returns `Right`
  /// even when the code is invalid (inspect `ValidateCodeResponse.valid` and
  /// `.message`); `Left` only on transport / server errors. Not cached — each
  /// validation is unique.
  Future<Either<Failure, ValidateCodeResponse>> validateCode({
    required String code,
    required String productId,
    required String platform,
  });
}
