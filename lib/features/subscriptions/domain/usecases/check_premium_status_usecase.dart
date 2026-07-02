import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/purchase_repository.dart';

/// Reports whether the account currently holds the `premium` entitlement per
/// RevenueCat's local `CustomerInfo`. This is the fast client-side entitlement
/// signal; the backend `/current` remains the source of truth for plan/counter
/// details (Commit 4).
class CheckPremiumStatusUseCase {
  final PurchaseRepository _repository;
  const CheckPremiumStatusUseCase(this._repository);

  Future<Either<Failure, bool>> call() => _repository.hasPremiumEntitlement();
}
