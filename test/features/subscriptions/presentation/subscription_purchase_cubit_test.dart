import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/discount_validation.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/usecases/subscribe_usecase.dart';
import 'package:qeran/features/subscriptions/domain/usecases/validate_discount_code_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/subscription_purchase_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/subscription_purchase_state.dart';

class _MockValidate extends Mock implements ValidateDiscountCodeUseCase {}

class _MockSubscribe extends Mock implements SubscribeUseCase {}

class _MockGateway extends Mock implements PaymentGateway {}

final _pricing = const SubscriptionPricing(
  id: 12,
  planId: 1,
  durationDays: 90,
  labelAr: '3 أشهر',
  labelEn: null,
  price: 26.99,
  originalPrice: 29.97,
  discountPercent: 10,
  monthlyEquivalent: 8.99,
  sortOrder: 1,
  isActive: true,
  isPopular: true,
);

CurrentSubscription _newSub() => CurrentSubscription(
      id: 7,
      plan: const SubscriptionPlan(
        id: 1,
        nameAr: 'Gold',
        nameEn: 'Gold',
        descriptionAr: null,
        descriptionEn: null,
        icon: '💎',
        color: '#D4AF37',
        sortOrder: 1,
        isActive: true,
        isPopular: false,
        features: SubscriptionFeatures(
          likesAllowed: 50,
          seriousInterestsAllowed: -1,
          photoExchangesAllowed: 5,
          dailyProfileViewsAllowed: -1,
        ),
        pricings: [],
      ),
      pricing: _pricing,
      startsAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
      likesUsed: 0,
      likesRemaining: 50,
      seriousInterestsUsed: 0,
      seriousInterestsRemaining: 2147483647,
      photoExchangesUsed: 0,
      photoExchangesRemaining: 5,
    );

void main() {
  setUpAll(() {
    // mocktail requires fallback values for any non-primitive
    // argument matched with `any(named: ...)`.
    registerFallbackValue(_pricing);
  });

  late _MockValidate validate;
  late _MockSubscribe subscribe;
  late _MockGateway gateway;
  late SubscriptionPurchaseCubit cubit;

  setUp(() {
    validate = _MockValidate();
    subscribe = _MockSubscribe();
    gateway = _MockGateway();
    cubit = SubscriptionPurchaseCubit(
      pricing: _pricing,
      validateDiscount: validate,
      subscribe: subscribe,
      paymentGateway: gateway,
    );
  });

  tearDown(() => cubit.close());

  group('discount validation', () {
    test('valid code → Idle with applied discount', () async {
      cubit.onDiscountInputChanged('WELCOME10');
      when(() => validate(code: any(named: 'code'), pricingId: any(named: 'pricingId')))
          .thenAnswer((_) async => const Right<Failure, DiscountValidation>(
                DiscountValidation(
                  isValid: true,
                  discountRate: 0.10,
                  originalPrice: 26.99,
                  finalPrice: 24.29,
                ),
              ));

      await cubit.applyDiscount();

      expect(cubit.state, isA<SubscriptionPurchaseIdle>());
      expect(cubit.state.discount?.isValid, isTrue);
      expect(cubit.effectivePrice, closeTo(24.29, 0.001));
    });

    test('invalid code → DiscountInvalid, effective price stays at pricing.price',
        () async {
      cubit.onDiscountInputChanged('BAD');
      when(() => validate(code: any(named: 'code'), pricingId: any(named: 'pricingId')))
          .thenAnswer((_) async => const Right<Failure, DiscountValidation>(
                DiscountValidation.invalid,
              ));

      await cubit.applyDiscount();

      expect(cubit.state, isA<SubscriptionPurchaseDiscountInvalid>());
      expect(cubit.effectivePrice, equals(_pricing.price));
    });

    test('removeDiscount clears applied state', () async {
      cubit.onDiscountInputChanged('WELCOME10');
      when(() => validate(code: any(named: 'code'), pricingId: any(named: 'pricingId')))
          .thenAnswer((_) async => const Right<Failure, DiscountValidation>(
                DiscountValidation(
                  isValid: true,
                  discountRate: 0.10,
                  originalPrice: 26.99,
                  finalPrice: 24.29,
                ),
              ));
      await cubit.applyDiscount();
      cubit.removeDiscount();
      expect(cubit.state.discount, isNull);
      expect(cubit.effectivePrice, equals(_pricing.price));
    });
  });

  group('confirmPurchase', () {
    test('payment cancelled → never calls /subscribe', () async {
      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => const PaymentResult.cancelled());

      await cubit.confirmPurchase();

      expect(cubit.state, isA<SubscriptionPurchaseIdle>());
      verifyNever(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          ));
    });

    test('payment failed → SubscriptionPurchaseFailure, /subscribe never called',
        () async {
      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async =>
              const PaymentResult.failed(message: 'gateway boom'));

      await cubit.confirmPurchase();

      expect(cubit.state, isA<SubscriptionPurchaseFailure>());
      verifyNever(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          ));
    });

    test('payment success → /subscribe called → Success', () async {
      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => const PaymentResult.success());
      final newSub = _newSub();
      when(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => Right(newSub));

      await cubit.confirmPurchase();

      expect(cubit.state, isA<SubscriptionPurchaseSuccess>());
      verify(() => subscribe(
            pricingId: _pricing.id,
            discountCode: null,
          )).called(1);
    });

    test('/subscribe failure surfaces as Failure', () async {
      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => const PaymentResult.success());
      when(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async =>
              const Left<Failure, CurrentSubscription>(
                ServerFailure(message: 'rate-limited'),
              ));

      await cubit.confirmPurchase();

      expect(cubit.state, isA<SubscriptionPurchaseFailure>());
    });

    test('valid discount is forwarded to /subscribe', () async {
      cubit.onDiscountInputChanged('WELCOME10');
      when(() => validate(code: any(named: 'code'), pricingId: any(named: 'pricingId')))
          .thenAnswer((_) async => const Right<Failure, DiscountValidation>(
                DiscountValidation(
                  isValid: true,
                  discountRate: 0.10,
                  originalPrice: 26.99,
                  finalPrice: 24.29,
                ),
              ));
      await cubit.applyDiscount();

      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => const PaymentResult.success());
      when(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) async => Right(_newSub()));

      await cubit.confirmPurchase();

      verify(() => subscribe(
            pricingId: _pricing.id,
            discountCode: 'WELCOME10',
          )).called(1);
    });
  });

  group('lifecycle', () {
    test('close mid-payment does not throw StateError', () async {
      final completer = Completer<PaymentResult>();
      when(() => gateway.payForPricing(
            pricing: any(named: 'pricing'),
            finalAmount: any(named: 'finalAmount'),
            discountCode: any(named: 'discountCode'),
          )).thenAnswer((_) => completer.future);

      final pending = cubit.confirmPurchase();
      await cubit.close();
      completer.complete(const PaymentResult.success());

      await expectLater(pending, completes);
      verifyNever(() => subscribe(
            pricingId: any(named: 'pricingId'),
            discountCode: any(named: 'discountCode'),
          ));
    });
  });
}
