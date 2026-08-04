import 'package:dartz/dartz.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

/// Store/RevenueCat side of subscriptions — an abstraction over
/// `RevenueCatService`. Deliberately surfaces the RC SDK types
/// ([Offering]/[Package]/[CustomerInfo]) since they are the purchase domain's
/// natural model; wrapping each in a bespoke entity would add no value here.
abstract interface class PurchaseRepository {
  /// The current offering configured in the RC dashboard.
  /// `Left(StoreUnavailableFailure)` when offerings can't be fetched / none is
  /// marked current.
  Future<Either<Failure, Offering>> getCurrentOffering();

  /// Finds the [Package] in the current offering whose
  /// `storeProduct.identifier` equals [productId].
  /// `Left(NotFoundFailure)` when no package matches.
  Future<Either<Failure, Package>> findPackage({required String productId});

  /// Purchases [package]. On Android an [offerId] selects the matching Google
  /// Play subscription offer; [oldProductId] (a different owned product) drives
  /// an upgrade with `WITH_TIME_PRORATION`. The iOS StoreKit promo quartet
  /// ([signature]/[keyId]/[nonce]/[timestampMs]) is accepted for forward-compat
  /// and only takes effect once a JWS signing service supplies it.
  Future<Either<Failure, CustomerInfo>> purchasePackage({
    required Package package,
    String? offerId,
    String? signature,
    String? keyId,
    String? nonce,
    int? timestampMs,
    String? oldProductId,
  });

  /// Restores prior purchases (reinstall / new device). `Left` on store error.
  Future<Either<Failure, CustomerInfo>> restorePurchases();

  /// Whether the account currently holds the `premium` entitlement.
  Future<Either<Failure, bool>> hasPremiumEntitlement();
}
