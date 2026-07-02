import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/purchase_repository.dart';

/// Restores prior store purchases (reinstall / new device / client-RC desync)
/// and returns the resulting [CustomerInfo]. Non-purchase action — allowed on
/// every platform, including the iOS lockdown (Q-B).
class RestorePurchasesUseCase {
  final PurchaseRepository _repository;
  const RestorePurchasesUseCase(this._repository);

  Future<Either<Failure, CustomerInfo>> call() =>
      _repository.restorePurchases();
}
