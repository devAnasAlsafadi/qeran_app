import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/features/subscriptions/domain/usecases/purchase_package_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/restore_purchases_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/validate_code_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';

class _FakeValidateCode extends Fake implements ValidateCodeUseCase {}

class _FakePurchasePackage extends Fake implements PurchasePackageUseCase {}

class _FakeCustomerInfo extends Fake implements CustomerInfo {}

class _FakeRestore extends Fake implements RestorePurchasesUseCase {
  _FakeRestore(this._result);
  final Either<Failure, CustomerInfo> _result;
  @override
  Future<Either<Failure, CustomerInfo>> call() async => _result;
}

class _FakeRevenueCat extends Fake implements RevenueCatService {
  @override
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {}
  @override
  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {}
}

/// Scripts `hasActiveSubscription` across successive reads and counts
/// `refresh` calls, so the backoff loop's shape is observable. Reads past the
/// script clamp to its last value (⇒ "always inactive" when `[false]`).
class _FakeCurrentSub extends Fake implements CurrentSubscriptionCubit {
  _FakeCurrentSub(this._activeScript);
  final List<bool> _activeScript;
  int refreshCount = 0;
  int _reads = 0;

  @override
  void invalidateCache() {}

  @override
  Future<void> refresh({bool force = false}) async {
    refreshCount++;
  }

  @override
  bool get hasActiveSubscription {
    final v = _reads < _activeScript.length
        ? _activeScript[_reads]
        : _activeScript.last;
    _reads++;
    return v;
  }
}

void main() {
  const zeroBackoff = <Duration>[
    Duration.zero,
    Duration.zero,
    Duration.zero,
    Duration.zero,
  ];

  PackagePurchaseCubit build(_FakeCurrentSub sub) => PackagePurchaseCubit(
        validateCode: _FakeValidateCode(),
        purchasePackage: _FakePurchasePackage(),
        restorePurchases:
            _FakeRestore(Right<Failure, CustomerInfo>(_FakeCustomerInfo())),
        currentSubscription: sub,
        revenueCat: _FakeRevenueCat(),
        reconcileBackoff: zeroBackoff,
      );

  group('post-purchase /current backoff', () {
    test('retries then succeeds — stops as soon as /current is active',
        () async {
      final sub = _FakeCurrentSub([false, false, true]);
      final cubit = build(sub);

      await cubit.restorePurchases();
      await pumpEventQueue();

      // Immediate fetch + 2 retries = 3, then early-exit on the active read.
      expect(sub.refreshCount, 3);
      await cubit.close();
    });

    test('gives up after the bound — no infinite loop', () async {
      final sub = _FakeCurrentSub([false]); // clamps → always inactive
      final cubit = build(sub);

      await cubit.restorePurchases();
      await pumpEventQueue();

      // Immediate fetch + 4 backoff retries = 5, then gives up gracefully.
      expect(sub.refreshCount, 1 + zeroBackoff.length);
      await cubit.close();
    });
  });
}
