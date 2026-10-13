import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/entities/validate_code_response.dart';
import 'package:qeran/features/subscriptions/domain/usecases/purchase_package_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/restore_purchases_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/validate_code_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/order_summary_widget.dart';

import '../../../core/shipped_strings_rig.dart';

/// Run 7, item 6: a discount code typed with Arabic digits reaches
/// `validate-code` in ASCII — shown so as it's typed, and sent so even when
/// the field holds something typing never put there.
class _CapturingValidateCode extends Fake implements ValidateCodeUseCase {
  final codes = <String>[];

  @override
  Future<Either<Failure, ValidateCodeResponse>> call({
    required String code,
    required String productId,
    required String platform,
  }) async {
    codes.add(code);
    return const Left(ServerFailure(message: 'x'));
  }
}

class _FakePurchase extends Fake implements PurchasePackageUseCase {}

class _FakeRestore extends Fake implements RestorePurchasesUseCase {}

class _FakeCurrent extends Fake implements CurrentSubscriptionCubit {}

const _pricing = SubscriptionPricing(
  id: 1,
  planId: 1,
  durationDays: 30,
  labelAr: 'شهر',
  labelEn: 'Month',
  price: 50,
  originalPrice: null,
  discountPercent: 0,
  monthlyEquivalent: 50,
  sortOrder: 1,
  isActive: true,
  isPopular: false,
  storeProductId: 'p1',
  appleProductId: null,
  googleProductId: null,
);

void main() {
  setUpAll(initShippedStrings);

  late _CapturingValidateCode validate;
  late PackagePurchaseCubit cubit;
  setUp(() {
    validate = _CapturingValidateCode();
    cubit = PackagePurchaseCubit(
      validateCode: validate,
      purchasePackage: _FakePurchase(),
      restorePurchases: _FakeRestore(),
      currentSubscription: _FakeCurrent(),
    );
  });
  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester) => pumpShippedStrings(
    tester,
    const Locale('ar'),
    child: SingleChildScrollView(
      child: BlocProvider.value(
        value: cubit,
        child: const OrderSummaryWidget(
          planName: 'Gold',
          pricing: _pricing,
          storeProduct: null,
          codeProductId: 'p1',
        ),
      ),
    ),
  );

  Future<void> tapValidate(WidgetTester tester) async {
    await tester.tap(find.byType(QeranButton));
    await tester.pump();
  }

  testWidgets('«٢٠٢٥» typed shows and is sent as 2025', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'qr٢٠٢٥');
    expect(find.text('qr2025'), findsOneWidget);
    await tapValidate(tester);
    expect(validate.codes, ['QR2025']);
  });

  testWidgets('a code put in the field around typing is sent in ASCII too', (
    tester,
  ) async {
    await pump(tester);
    tester.widget<TextField>(find.byType(TextField)).controller!.text = '۲۰۲۵';
    await tapValidate(tester);
    expect(validate.codes, ['2025']);
  });
}
