import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/config/revenuecat_config.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';

import '../../domain/repositories/purchase_repository.dart';
import 'purchase_error_mapper.dart';
import 'purchase_params.dart';

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
          final storeId = package.storeProduct.identifier;
          final packageId = package.identifier;
          if (storeId == productId ||
              storeId.split(':').first == productId ||
              packageId == productId ||
              storeId.toLowerCase() == productId.toLowerCase() ||
              packageId.toLowerCase() == productId.toLowerCase()) {
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
    try {
      final params = buildPurchaseParams(
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
  Future<String?> replaceableProductId() async {
    final info = await _rc.getCustomerInfo();
    final premium =
        info?.entitlements.active[RevenueCatConfig.premiumEntitlementId];
    if (premium == null || premium.store != Store.playStore) return null;
    final product = premium.productIdentifier;
    final basePlan = premium.productPlanIdentifier;
    return product.contains(':') || basePlan == null
        ? product
        : '$product:$basePlan';
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
}
