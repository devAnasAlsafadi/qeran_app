import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/validate_code_response.dart';
import '../repositories/subscriptions_repository.dart';

/// Validates a discount code against a specific store product + platform,
/// returning the offer id (+ iOS signature) to hand to RevenueCat. A `false`
/// [ValidateCodeResponse.valid] is a **successful** result (a Right carrying
/// the reason [ValidateCodeResponse.message]) — a Left is only a transport /
/// server error. See docs/PAYWALL_IMPLEMENTATION_PLAN.md §2.4/§2.5.
class ValidateCodeUseCase {
  final SubscriptionsRepository _repository;
  const ValidateCodeUseCase(this._repository);

  Future<Either<Failure, ValidateCodeResponse>> call({
    required String code,
    required String productId,
    required String platform,
  }) =>
      _repository.validateCode(
        code: code,
        productId: productId,
        platform: platform,
      );
}
