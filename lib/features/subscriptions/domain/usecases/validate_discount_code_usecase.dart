import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/discount_validation.dart';
import '../repositories/subscriptions_repository.dart';

class ValidateDiscountCodeUseCase {
  final SubscriptionsRepository _repository;
  const ValidateDiscountCodeUseCase(this._repository);

  Future<Either<Failure, DiscountValidation>> call({
    required String code,
    required int pricingId,
  }) =>
      _repository.validateDiscount(code: code, pricingId: pricingId);
}
