import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/purchase_repository.dart';

/// Orchestrates a store purchase: resolve the [Package] for [productId], then
/// buy it (optionally with an Android [offerId] discount, or the iOS promo
/// quartet). Returns the post-purchase [CustomerInfo]. Backend `/current`
/// reconciliation is the caller's job.
///
/// An upgrade replaces the Google Play purchase RevenueCat's entitlement
/// names, never `/current`'s product (run 11): a plan granted by hand has no
/// store purchase, so it is bought without replacing anything. Buying the
/// very product and base plan already owned is [AlreadyOwnedFailure].
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
  }) async {
    final packageResult = await _repository.findPackage(productId: productId);
    return packageResult.fold((failure) => Future.value(Left(failure)), (
      package,
    ) async {
      final owned = await _repository.replaceableProductId();
      if (owned == package.storeProduct.identifier) {
        return const Left(AlreadyOwnedFailure());
      }
      return _repository.purchasePackage(
        package: package,
        offerId: offerId,
        signature: signature,
        keyId: keyId,
        nonce: nonce,
        timestampMs: timestampMs,
        oldProductId: owned?.split(':').first,
      );
    });
  }
}
