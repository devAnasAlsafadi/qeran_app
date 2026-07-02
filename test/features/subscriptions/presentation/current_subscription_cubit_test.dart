import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';

class _MockGetCurrent extends Mock implements GetCurrentSubscriptionUseCase {}

CurrentSubscription _sub({
  required DateTime expiresAt,
  int likesRemaining = 38,
}) =>
    CurrentSubscription(
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
        isFree: false,
        features: SubscriptionFeatures(
          likesAllowed: 50,
          seriousInterestsAllowed: -1,
          photoExchangesAllowed: 5,
          dailyProfileViewsAllowed: -1,
        ),
        pricings: [],
      ),
      pricing: const SubscriptionPricing(
        id: 12,
        planId: 1,
        durationDays: 90,
        labelAr: '3 أشهر',
        labelEn: null,
        price: 26.99,
        originalPrice: null,
        discountPercent: 0,
        monthlyEquivalent: 8.99,
        sortOrder: 1,
        isActive: true,
        isPopular: true,
        appleProductId: null,
        googleProductId: null,
      ),
      startsAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: expiresAt,
      isActive: true,
      likesUsed: 12,
      likesRemaining: likesRemaining,
      seriousInterestsUsed: 0,
      seriousInterestsRemaining: 2147483647,
      photoExchangesUsed: 0,
      photoExchangesRemaining: 5,
    );

void main() {
  late _MockGetCurrent getCurrent;
  late CurrentSubscriptionCubit cubit;

  setUp(() {
    getCurrent = _MockGetCurrent();
    cubit = CurrentSubscriptionCubit(getCurrent: getCurrent);
  });

  tearDown(() => cubit.close());

  test('Loaded when /current returns a subscription', () async {
    final sub = _sub(expiresAt: DateTime.now().add(const Duration(days: 30)));
    when(() => getCurrent()).thenAnswer((_) async => Right(sub));

    await cubit.hydrate();

    expect(cubit.state, isA<CurrentSubscriptionLoaded>());
    expect(cubit.hasActiveSubscription, isTrue);
    expect(cubit.subscription, equals(sub));
  });

  test('None when /current returns null', () async {
    when(() => getCurrent())
        .thenAnswer((_) async => const Right<Failure, CurrentSubscription?>(null));

    await cubit.hydrate();

    expect(cubit.state, isA<CurrentSubscriptionNone>());
    expect(cubit.subscription, isNull);
    expect(cubit.hasActiveSubscription, isFalse);
  });

  test('expired subscription → isCurrentlyActive == false', () async {
    final expired =
        _sub(expiresAt: DateTime.now().subtract(const Duration(days: 1)));
    when(() => getCurrent()).thenAnswer((_) async => Right(expired));

    await cubit.hydrate();

    expect(cubit.state, isA<CurrentSubscriptionLoaded>());
    // Loaded but expiresAt is in the past.
    expect(cubit.hasActiveSubscription, isFalse);
  });

  test('Failure carries the previous payload as lastKnown', () async {
    final sub =
        _sub(expiresAt: DateTime.now().add(const Duration(days: 10)));
    when(() => getCurrent()).thenAnswer((_) async => Right(sub));
    await cubit.hydrate();

    when(() => getCurrent()).thenAnswer(
      (_) async => const Left<Failure, CurrentSubscription?>(
        ServerFailure(message: 'boom'),
      ),
    );
    await cubit.refresh(force: true);

    expect(cubit.state, isA<CurrentSubscriptionFailure>());
    final f = cubit.state as CurrentSubscriptionFailure;
    expect(f.lastKnown, equals(sub));
  });

  test('TTL: second non-forced refresh is a no-op', () async {
    when(() => getCurrent()).thenAnswer(
      (_) async => const Right<Failure, CurrentSubscription?>(null),
    );
    await cubit.hydrate();
    await cubit.refresh();
    await cubit.refresh();
    verify(() => getCurrent()).called(1);
  });

  test('TTL: forced refresh always hits the use case', () async {
    when(() => getCurrent()).thenAnswer(
      (_) async => const Right<Failure, CurrentSubscription?>(null),
    );
    await cubit.hydrate();
    await cubit.refresh(force: true);
    verify(() => getCurrent()).called(2);
  });

  test('onSubscribed pushes state directly — no /current call', () {
    final sub =
        _sub(expiresAt: DateTime.now().add(const Duration(days: 90)));
    cubit.onSubscribed(sub);
    expect(cubit.state, isA<CurrentSubscriptionLoaded>());
    expect(cubit.hasActiveSubscription, isTrue);
    verifyNever(() => getCurrent());
  });

  test('clear resets state to Initial', () async {
    when(() => getCurrent()).thenAnswer(
      (_) async => Right(
        _sub(expiresAt: DateTime.now().add(const Duration(days: 10))),
      ),
    );
    await cubit.hydrate();
    cubit.clear();
    expect(cubit.state, isA<CurrentSubscriptionInitial>());
  });

  test('close before /current completes does not throw StateError',
      () async {
    final completer = Completer<Either<Failure, CurrentSubscription?>>();
    when(() => getCurrent()).thenAnswer((_) => completer.future);

    final pending = cubit.refresh(force: true);
    await cubit.close();
    completer.complete(
      const Right<Failure, CurrentSubscription?>(null),
    );

    await expectLater(pending, completes);
  });
}
