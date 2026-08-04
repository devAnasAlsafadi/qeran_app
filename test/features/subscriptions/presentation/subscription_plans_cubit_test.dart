import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_store_products_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_subscription_plans_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';

class _MockGetPlans extends Mock implements GetSubscriptionPlansUseCase {}

class _MockGetStoreProducts extends Mock implements GetStoreProductsUseCase {}

class _MockStoreProduct extends Mock implements StoreProduct {}

const _productId = 'qeran_vip_monthly';

SubscriptionPlan _plan() => const SubscriptionPlan(
      id: 2,
      nameAr: 'VIP',
      nameEn: 'VIP',
      descriptionAr: null,
      descriptionEn: null,
      icon: '💎',
      color: '#D4AF37',
      sortOrder: 1,
      isActive: true,
      isPopular: true,
      isFree: false,
      features: SubscriptionFeatures(
        likesAllowed: -1,
        seriousInterestsAllowed: -1,
        photoExchangesAllowed: -1,
        dailyProfileViewsAllowed: -1,
      ),
      pricings: [
        SubscriptionPricing(
          id: 3,
          planId: 2,
          durationDays: 30,
          labelAr: 'شهر',
          labelEn: 'Month',
          price: 50.0,
          originalPrice: null,
          discountPercent: 0,
          monthlyEquivalent: 50.0,
          sortOrder: 1,
          isActive: true,
          isPopular: false,
          storeProductId: _productId,
          appleProductId: _productId,
          googleProductId: _productId,
        ),
      ],
    );

void main() {
  late _MockGetPlans getPlans;
  late _MockGetStoreProducts getStoreProducts;
  late SubscriptionPlansCubit cubit;

  setUp(() {
    getPlans = _MockGetPlans();
    getStoreProducts = _MockGetStoreProducts();
    cubit = SubscriptionPlansCubit(
      getPlans: getPlans,
      getStoreProducts: getStoreProducts,
    );
  });

  tearDown(() => cubit.close());

  test('store-merge: plans paint first, then store products augment', () async {
    final product = _MockStoreProduct();
    when(() => getPlans()).thenAnswer((_) async => Right([_plan()]));
    when(() => getStoreProducts())
        .thenAnswer((_) async => Right({_productId: product}));

    final emitted = <SubscriptionPlansState>[];
    final sub = cubit.stream.listen(emitted.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero); // flush stream deliveries
    await sub.cancel();

    expect(emitted, hasLength(3));
    expect(emitted[0], isA<SubscriptionPlansLoading>());

    // Second emit: backend prices only, store catalogue still empty.
    final backendOnly = emitted[1] as SubscriptionPlansLoaded;
    expect(backendOnly.storeProducts, isEmpty);

    // Third emit: store catalogue merged in.
    final merged = emitted[2] as SubscriptionPlansLoaded;
    expect(merged.storeProducts, {_productId: product});
    expect(merged.storeResolved, isTrue);
    expect(
      merged.storeProductFor(merged.plans.first.pricings.first, isIOS: false),
      same(product),
    );
  });

  test('store failure: a third emit marks storeResolved with no products',
      () async {
    when(() => getPlans()).thenAnswer((_) async => Right([_plan()]));
    when(() => getStoreProducts())
        .thenAnswer((_) async => const Left(StoreUnavailableFailure()));

    final emitted = <SubscriptionPlansState>[];
    final sub = cubit.stream.listen(emitted.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero); // flush stream deliveries
    await sub.cancel();

    // Loading → Loaded(unresolved) → Loaded(resolved, still no products). The
    // third emit is what lets the paywall stop showing a price placeholder and
    // say the price is unavailable instead of inventing a backend figure.
    expect(emitted, hasLength(3));
    expect((emitted[1] as SubscriptionPlansLoaded).storeResolved, isFalse);
    final resolved = emitted[2] as SubscriptionPlansLoaded;
    expect(resolved.storeResolved, isTrue);
    expect(resolved.storeProducts, isEmpty);
  });

  test('empty store catalogue: still marks storeResolved', () async {
    when(() => getPlans()).thenAnswer((_) async => Right([_plan()]));
    when(() => getStoreProducts())
        .thenAnswer((_) async => const Right({}));

    final emitted = <SubscriptionPlansState>[];
    final sub = cubit.stream.listen(emitted.add);
    await cubit.load();
    await Future<void>.delayed(Duration.zero); // flush stream deliveries
    await sub.cancel();

    expect(emitted, hasLength(3));
    final resolved = emitted[2] as SubscriptionPlansLoaded;
    expect(resolved.storeResolved, isTrue);
    expect(resolved.storeProducts, isEmpty);
  });

  test('plans failure: store products never fetched', () async {
    when(() => getPlans()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'boom')),
    );

    await cubit.load();

    expect(cubit.state, isA<SubscriptionPlansFailure>());
    verifyNever(() => getStoreProducts());
  });
}
