import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';

/// Builds the [PurchaseParams] for the current platform. Upgrades from a
/// different owned product prorate with `WITH_TIME_PRORATION` (a Play-only
/// setting that StoreKit ignores).
PurchaseParams buildPurchaseParams({
  required Package package,
  String? offerId,
  String? signature,
  String? keyId,
  String? nonce,
  int? timestampMs,
  String? oldProductId,
}) {
  final change =
      (oldProductId != null &&
          oldProductId.isNotEmpty &&
          oldProductId != package.storeProduct.identifier)
      ? StoreProductChangeInfo(
          oldProductId,
          replacementMode: StoreReplacementMode.withTimeProration,
        )
      : null;

  // iOS StoreKit promotional offer. Ignored by the Play SDK, and only taken
  // when the backend returns a full StoreKit signature — which needs a JWS
  // signing service that does not exist yet, so in practice iOS discounts
  // ride App Store Offer Codes instead and this branch stays unused.
  if (offerId != null &&
      signature != null &&
      keyId != null &&
      nonce != null &&
      timestampMs != null) {
    return PurchaseParams.package(
      package,
      promotionalOffer: PromotionalOffer(
        offerId,
        keyId,
        nonce,
        signature,
        timestampMs,
      ),
      productChangeInfo: change,
    );
  }

  final options = package.storeProduct.subscriptionOptions;
  if (options != null && options.isNotEmpty) {
    if (offerId != null && offerId.isNotEmpty) {
      final option = _findOption(package, offerId);
      if (option != null) {
        return PurchaseParams.subscriptionOption(
          option,
          productChangeInfo: change,
        );
      }
      AppLogger.warning(
        'Offer "$offerId" not found on ${package.storeProduct.identifier} — '
        'falling back to the base plan',
        tag: 'RC',
      );
    }

    // No offer or offer not found: find the base plan SubscriptionOption
    SubscriptionOption? basePlanOption;
    for (final option in options) {
      if (option.isBasePlan) {
        basePlanOption = option;
        break;
      }
    }

    if (basePlanOption != null) {
      return PurchaseParams.subscriptionOption(
        basePlanOption,
        productChangeInfo: change,
      );
    }

    AppLogger.warning(
      'No base plan option found in subscription options for ${package.storeProduct.identifier}. '
      'Falling back to default package purchase.',
      tag: 'RC',
    );
  }

  return PurchaseParams.package(package, productChangeInfo: change);
}

/// Finds the Google Play [SubscriptionOption] for [offerId]. RC option ids
/// are often `"<basePlanId>:<offerId>"`, so an exact match is tried first,
/// then a suffix match. (Exact string format confirmed on-device — Q-D.)
SubscriptionOption? _findOption(Package package, String offerId) {
  final options = package.storeProduct.subscriptionOptions;
  if (options == null || options.isEmpty) return null;
  for (final option in options) {
    if (option.id == offerId) return option;
  }
  for (final option in options) {
    if (option.id.split(':').last == offerId) return option;
  }
  for (final option in options) {
    if (option.id.endsWith(':$offerId') || option.id.endsWith(offerId)) {
      return option;
    }
  }
  return null;
}
