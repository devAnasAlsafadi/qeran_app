import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/purchase_repository.dart';

/// Fetches the current RevenueCat offering and flattens it into a lookup of
/// [StoreProduct] keyed by `storeProduct.identifier`. The paywall keys off this
/// map by a pricing's platform store id (`appleProductId` / `googleProductId`)
/// to bind the store's localized price string as the displayed/charged price.
///
/// The store is the source of truth for price; backend pricing is the fallback
/// when a product is missing (see `SubscriptionPlansCubit`). A store hiccup
/// therefore surfaces as `Left(Failure)` and the caller degrades to backend
/// prices — it must never break the paywall.
class GetStoreProductsUseCase {
  final PurchaseRepository _repository;
  const GetStoreProductsUseCase(this._repository);

  Future<Either<Failure, Map<String, StoreProduct>>> call() async {
    final offeringResult = await _repository.getCurrentOffering();
    return offeringResult.map((offering) {
      final products = <String, StoreProduct>{};
      for (final package in offering.availablePackages) {
        final product = package.storeProduct;
        // Google Play subscription store ids are "<productId>:<basePlanId>";
        // the paywall keys off the backend googleProductId (the bare portion).
        // Register both so a lookup by either shape resolves the store price
        // instead of silently falling back to the backend price.
        products[product.identifier] = product;
        products[product.identifier.split(':').first] = product;
      }
      return products;
    });
  }
}
