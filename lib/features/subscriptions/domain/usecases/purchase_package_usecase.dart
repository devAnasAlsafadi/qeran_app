import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/purchase_repository.dart';

/// Orchestrates a store purchase: resolve the [Package] for [productId], then
/// buy it (optionally with an Android [offerId] discount, an upgrade from
/// [oldProductId], or the iOS promo quartet). Returns the post-purchase
/// [CustomerInfo]. Backend `/current` reconciliation is the caller's job
/// (Commit 4). See docs/PAYWALL_IMPLEMENTATION_PLAN.md §Commit 3/4.
class PurchasePackageUseCase {
  final PurchaseRepository _repository;
  const PurchasePackageUseCase(this._repository);

  Future<Either<Failure, CustomerInfo>> call({
    required String productId,
    String? offerId,
    String? signature,
    String? keyId,
    String? nonce,
    int? timestampMs,
    String? oldProductId,
  }) async {
    final packageResult = await _repository.findPackage(productId: productId);
    return packageResult.fold(
      (failure) => Future.value(Left(failure)),
      (package) => _repository.purchasePackage(
        package: package,
        offerId: offerId,
        signature: signature,
        keyId: keyId,
        nonce: nonce,
        timestampMs: timestampMs,
        oldProductId: oldProductId,
      ),
    );
  }
}
