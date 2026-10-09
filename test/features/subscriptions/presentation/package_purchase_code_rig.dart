import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/revenuecat_service.dart';
import 'package:qeran/features/subscriptions/domain/entities/validate_code_response.dart';
import 'package:qeran/features/subscriptions/domain/usecases/purchase_package_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/restore_purchases_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/validate_code_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';

/// A `PackagePurchaseCubit` whose `validate-code` answer is scripted, for the
/// discount-field tests.
class _ScriptedValidateCode extends Fake implements ValidateCodeUseCase {
  _ScriptedValidateCode(this._result);
  final Either<Failure, ValidateCodeResponse> _result;

  @override
  Future<Either<Failure, ValidateCodeResponse>> call({
    required String code,
    required String productId,
    required String platform,
  }) async => _result;
}

class _FakePurchasePackage extends Fake implements PurchasePackageUseCase {}

class _FakeCustomerInfo extends Fake implements CustomerInfo {}

class _FakeRestore extends Fake implements RestorePurchasesUseCase {
  @override
  Future<Either<Failure, CustomerInfo>> call() async =>
      Right<Failure, CustomerInfo>(_FakeCustomerInfo());
}

class _FakeRevenueCat extends Fake implements RevenueCatService {
  @override
  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {}
  @override
  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {}
}

class _FakeCurrentSub extends Fake implements CurrentSubscriptionCubit {
  @override
  void invalidateCache() {}
  @override
  Future<void> refresh({bool force = false}) async {}
  @override
  bool get hasActiveSubscription => false;
}

/// The exact sentence the backend sends today, so a mutant that forwards it
/// fails on the real string rather than a stand-in.
const serverProse = 'كود غير صالح أو منتهي الصلاحية';

ValidateCodeResponse rejected({String? message, String? errorCode}) =>
    ValidateCodeResponse(
      valid: false,
      discountPercent: 0,
      offerId: null,
      signature: null,
      keyId: null,
      nonce: null,
      timestampMs: null,
      message: message,
      errorCode: errorCode,
    );

PackagePurchaseCubit cubitFor(Either<Failure, ValidateCodeResponse> result) =>
    PackagePurchaseCubit(
      validateCode: _ScriptedValidateCode(result),
      purchasePackage: _FakePurchasePackage(),
      restorePurchases: _FakeRestore(),
      currentSubscription: _FakeCurrentSub(),
      revenueCat: _FakeRevenueCat(),
    );

Future<PackagePurchaseState> validate(PackagePurchaseCubit cubit) async {
  await cubit.validateDiscountCode(code: 'MQ', productId: 'p1');
  return cubit.state;
}
