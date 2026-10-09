import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/config/revenuecat_config.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/usecases/purchase_package_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/restore_purchases_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/validate_code_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';

class _FakeValidateCode extends Fake implements ValidateCodeUseCase {}

class _FakeEntitlement extends Fake implements EntitlementInfo {}

/// A store answer, with or without the premium entitlement active.
class _FakeInfos extends Fake implements EntitlementInfos {
  _FakeInfos({required this.premium});
  final bool premium;
  @override
  Map<String, EntitlementInfo> get active => {
    if (premium) RevenueCatConfig.premiumEntitlementId: _FakeEntitlement(),
  };
}

class _FakeCustomerInfo extends Fake implements CustomerInfo {
  _FakeCustomerInfo({required bool premium})
    : entitlements = _FakeInfos(premium: premium);
  @override
  final EntitlementInfos entitlements;
}

class _FakePurchase extends Fake implements PurchasePackageUseCase {
  @override
  Future<Either<Failure, CustomerInfo>> call({
    required String productId,
    String? offerId,
    String? signature,
    String? keyId,
    String? nonce,
    int? timestampMs,
    String? oldProductId,
  }) async => Right(_FakeCustomerInfo(premium: true));
}

class _FakeRestore extends Fake implements RestorePurchasesUseCase {
  _FakeRestore({required this.premium});
  final bool premium;
  @override
  Future<Either<Failure, CustomerInfo>> call() async =>
      Right(_FakeCustomerInfo(premium: premium));
}

/// Counts the store confirmations handed over.
class _FakeCurrentSub extends Fake implements CurrentSubscriptionCubit {
  int confirmed = 0;
  @override
  Future<void> onStoreConfirmed() async => confirmed++;
}

const _pricing = SubscriptionPricing(
  id: 12,
  planId: 1,
  durationDays: 30,
  labelAr: null,
  labelEn: null,
  price: 9.99,
  originalPrice: null,
  discountPercent: 0,
  monthlyEquivalent: 9.99,
  sortOrder: 1,
  isActive: true,
  isPopular: false,
  storeProductId: 'qeran_basic_monthly',
  appleProductId: null,
  googleProductId: null,
);

/// C5: after the store confirms, the wait for the server is the app-scoped
/// [CurrentSubscriptionCubit]'s — it outlives the paywall. This cubit only
/// hands it over: every purchase, and a restore that found something active.
void main() {
  late _FakeCurrentSub current;

  PackagePurchaseCubit build({bool restoredPremium = true}) =>
      PackagePurchaseCubit(
        validateCode: _FakeValidateCode(),
        purchasePackage: _FakePurchase(),
        restorePurchases: _FakeRestore(premium: restoredPremium),
        currentSubscription: current,
      );

  setUp(() => current = _FakeCurrentSub());

  test('a purchase hands the wait over, then succeeds', () async {
    final cubit = build();

    await cubit.purchase(pricing: _pricing);

    expect(current.confirmed, 1);
    expect(cubit.state, isA<PackagePurchaseSuccess>());
    await cubit.close();
  });

  test('a restore that found an active purchase hands it over', () async {
    final cubit = build();

    await cubit.restorePurchases();

    expect(current.confirmed, 1);
    expect(cubit.state, isA<PackagePurchaseSuccess>());
    await cubit.close();
  });

  test('a restore that found nothing active confirms nothing', () async {
    final cubit = build(restoredPremium: false);

    await cubit.restorePurchases();

    expect(current.confirmed, 0);
    expect(cubit.state, isA<PackagePurchaseSuccess>());
    await cubit.close();
  });
}
