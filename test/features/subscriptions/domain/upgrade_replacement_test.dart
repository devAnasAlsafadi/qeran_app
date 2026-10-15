import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/config/revenuecat_config.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/features/subscriptions/data/repositories/purchase_repository_impl.dart';
import 'package:qeran/features/subscriptions/domain/repositories/purchase_repository.dart';
import 'package:qeran/features/subscriptions/domain/usecases/purchase_package_usecase.dart';

class _MockRc extends Mock implements RevenueCatService {}

class _FakeInfo extends Fake implements CustomerInfo {
  _FakeInfo(Map<String, EntitlementInfo> active)
    : entitlements = EntitlementInfos(active, active);
  @override
  final EntitlementInfos entitlements;
}

class _FakeProduct extends Fake implements StoreProduct {
  _FakeProduct(this.identifier);
  @override
  final String identifier;
}

class _FakePackage extends Fake implements Package {
  _FakePackage(String id) : storeProduct = _FakeProduct(id);
  @override
  final StoreProduct storeProduct;
}

/// The store side of [PurchaseRepositoryImpl], scripted: the package found
/// and what was bought with which replacement.
class _Repo extends PurchaseRepositoryImpl {
  _Repo(super.rc, this.package);
  final Package package;
  final bought = <String?>[];

  @override
  Future<Either<Failure, Package>> findPackage({
    required String productId,
  }) async => Right(package);

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
    bought.add(oldProductId);
    return Right(_FakeInfo(const {}));
  }
}

EntitlementInfo _premium(String product, {String? basePlan, Store? store}) =>
    EntitlementInfo(
      RevenueCatConfig.premiumEntitlementId,
      true,
      true,
      '2026-10-01',
      '2026-10-01',
      product,
      false,
      store: store ?? Store.playStore,
      productPlanIdentifier: basePlan,
    );

/// Run 11 (Anas): an upgrade replaces the Google Play purchase RevenueCat's
/// premium entitlement names, never `/current`'s product. A plan granted by
/// hand has no store purchase, so it is bought without replacing anything.
void main() {
  late _MockRc rc;
  setUp(() => rc = _MockRc());

  void entitled(EntitlementInfo? premium) =>
      when(() => rc.getCustomerInfo()).thenAnswer(
        (_) async =>
            _FakeInfo({RevenueCatConfig.premiumEntitlementId: ?premium}),
      );

  /// Buys [target] and answers the product it replaced.
  Future<String?> upgradeTo(String target) async {
    final repo = _Repo(rc, _FakePackage(target));
    final result = await PurchasePackageUseCase(repo)(productId: target);
    expect(result.isRight(), isTrue);
    return repo.bought.single;
  }

  group('what an upgrade replaces', () {
    test('VIP monthly on Google Play → VIP 3 months replaces it', () async {
      entitled(_premium('qeran_vip_monthly', basePlan: 'vip-monthly'));
      expect(
        await upgradeTo('qeran_vip_3month:vip-quarterly'),
        'qeran_vip_monthly',
      );
    });

    test('VIP 3 months on Google Play → VIP monthly replaces it', () async {
      entitled(_premium('qeran_vip_3month', basePlan: 'vip-quarterly'));
      expect(
        await upgradeTo('qeran_vip_monthly:vip-monthly'),
        'qeran_vip_3month',
      );
    });

    test('Basic on Google Play → VIP replaces it', () async {
      entitled(_premium('qeran_basic_monthly:basic-monthly'));
      expect(
        await upgradeTo('qeran_vip_monthly:vip-monthly'),
        'qeran_basic_monthly',
      );
    });

    test('Free (no store entitlement): nothing to replace', () async {
      entitled(null);
      expect(await upgradeTo('qeran_basic_monthly:basic-monthly'), isNull);
    });

    test(
      'a manual grant: nothing to replace, whatever /current says',
      () async {
        // Granted in the dashboard only: RevenueCat has no entitlement.
        entitled(null);
        expect(await upgradeTo('qeran_vip_3month:vip-quarterly'), isNull);

        // Granted as a RevenueCat promotional entitlement.
        entitled(
          _premium('rc_promo_premium_monthly', store: Store.promotional),
        );
        expect(await upgradeTo('qeran_vip_3month:vip-quarterly'), isNull);
      },
    );

    test('none: the store did not answer, nothing to replace', () async {
      when(() => rc.getCustomerInfo()).thenAnswer((_) async => null);
      expect(await upgradeTo('qeran_vip_monthly:vip-monthly'), isNull);
    });

    test(
      'bought on the App Store: StoreKit upgrades within its group',
      () async {
        entitled(_premium('qeran_vip_monthly', store: Store.appStore));
        expect(await upgradeTo('qeran_vip_3month'), isNull);
      },
    );
  });

  test('the very product and base plan owned: nothing is bought', () async {
    entitled(_premium('qeran_vip_monthly', basePlan: 'vip-monthly'));
    final repo = _Repo(rc, _FakePackage('qeran_vip_monthly:vip-monthly'));

    final result = await PurchasePackageUseCase(repo)(
      productId: 'qeran_vip_monthly',
    );

    expect(result, const Left<Failure, CustomerInfo>(AlreadyOwnedFailure()));
    expect(repo.bought, isEmpty);
  });

  test('the repository reads the store, the base plan included', () async {
    final PurchaseRepository repo = PurchaseRepositoryImpl(rc);
    entitled(_premium('qeran_vip_monthly', basePlan: 'vip-monthly'));
    expect(await repo.replaceableProductId(), 'qeran_vip_monthly:vip-monthly');

    entitled(_premium('qeran_vip_monthly'));
    expect(await repo.replaceableProductId(), 'qeran_vip_monthly');
  });
}
