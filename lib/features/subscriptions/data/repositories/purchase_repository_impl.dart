import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';

import '../../domain/repositories/purchase_repository.dart';
import 'purchase_error_mapper.dart';

/// [PurchaseRepository] over [RevenueCatService]. RC access stays in the
/// service; this layer resolves packages, builds [PurchaseParams], and
/// classifies store errors into typed [Failure]s.
class PurchaseRepositoryImpl implements PurchaseRepository {
  final RevenueCatService _rc;

  PurchaseRepositoryImpl(this._rc);

  @override
  Future<Either<Failure, Offering>> getCurrentOffering() async {
    final offerings = await _rc.getOfferings();
    final current = offerings?.current;
    if (current == null) return const Left(StoreUnavailableFailure());
    return Right(current);
  }

  @override
  Future<Either<Failure, Package>> findPackage({
    required String productId,
  }) async {
    final offeringResult = await getCurrentOffering();
    return offeringResult.fold(
      Left.new,
      (offering) {
        for (final package in offering.availablePackages) {
          // Google Play subscription store ids are "<productId>:<basePlanId>"
          // (one productId can carry several base plans); iOS/others are the
          // bare productId. Match the productId portion against the backend
          // googleProductId. (Play product ids never contain ':'.)
          final storeId = package.storeProduct.identifier;
          if (storeId == productId || storeId.split(':').first == productId) {
            return Right(package);
          }
        }
        AppLogger.warning(
          'No package for productId "$productId" in offering '
          '"${offering.identifier}"',
          tag: 'RC',
        );
        return const Left(NotFoundFailure());
      },
    );
  }

  @override
  Future<Either<Failure, CustomerInfo>> purchasePackage({
    required Package package,
    String? offerId,
    String? signature,
    String? keyId,
    String? nonce,
    int? timestampMs,
    String? oldProductId,
  }) async {
    // Q-B: iOS purchases are fully locked this cycle. Defensive backstop —
    // the paywall UI also gates iOS before we get here.
    if (Platform.isIOS) return const Left(PlatformNotSupportedFailure());
    try {
      final params = _buildParams(
        package: package,
        offerId: offerId,
        signature: signature,
        keyId: keyId,
        nonce: nonce,
        timestampMs: timestampMs,
        oldProductId: oldProductId,
      );
      final info = await _rc.purchase(params);
      return Right(info);
    } on PlatformException catch (e) {
      return Left(mapPurchaseError(e));
    } catch (e, s) {
      AppLogger.error('Purchase failed (non-platform)',
          error: e, stack: s, tag: 'RC');
      return Left(
        GenericPurchaseFailure(errorCode: 'unknown', underlyingMessage: '$e'),
      );
    }
  }

  @override
  Future<Either<Failure, CustomerInfo>> restorePurchases() async {
    final info = await _rc.restorePurchases();
    if (info == null) return const Left(StoreUnavailableFailure());
    return Right(info);
  }

  @override
  Future<Either<Failure, bool>> hasPremiumEntitlement() async {
    final info = await _rc.getCustomerInfo();
    if (info == null) return const Left(StoreUnavailableFailure());
    return Right(_rc.hasPremium(info));
  }

  /// Builds the [PurchaseParams] for the current platform (Android). Upgrades
  /// from a different owned product prorate with `WITH_TIME_PRORATION`.
  PurchaseParams _buildParams({
    required Package package,
    String? offerId,
    String? signature,
    String? keyId,
    String? nonce,
    int? timestampMs,
    String? oldProductId,
  }) {
    final change = (oldProductId != null &&
            oldProductId.isNotEmpty &&
            oldProductId != package.storeProduct.identifier)
        ? StoreProductChangeInfo(
            oldProductId,
            replacementMode: StoreReplacementMode.withTimeProration,
          )
        : null;

    // iOS StoreKit promotional offer. Dormant while iOS is locked (the method
    // returns early above) and ignored by the Play SDK — built here so the
    // signature is forward-compatible for the iOS unlock.
    if (offerId != null &&
        signature != null &&
        keyId != null &&
        nonce != null &&
        timestampMs != null) {
      return PurchaseParams.package(
        package,
        promotionalOffer:
            PromotionalOffer(offerId, keyId, nonce, signature, timestampMs),
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
}
