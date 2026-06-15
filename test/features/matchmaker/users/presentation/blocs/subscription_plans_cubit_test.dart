import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/subscription_plan.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/fetch_subscription_plans_usecase.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/subscription_plans_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/subscription_plans_state.dart';

class _MockFetchPlans extends Mock implements FetchSubscriptionPlansUseCase {}

const _plans = [
  SubscriptionPlan(planId: 1, nameAr: 'الذهبية', nameEn: 'Gold', subscriberCount: 5),
  SubscriptionPlan(planId: 2, nameAr: 'البريميوم', nameEn: 'Premium', subscriberCount: 2),
];

void main() {
  late _MockFetchPlans fetch;
  late SubscriptionPlansCubit cubit;

  setUp(() {
    fetch = _MockFetchPlans();
    cubit = SubscriptionPlansCubit(fetchPlans: fetch);
  });

  tearDown(() => cubit.close());

  test('initial state: initial status, no plans, selection null (All)', () {
    expect(cubit.state.status, SubscriptionPlansStatus.initial);
    expect(cubit.state.plans, isEmpty);
    expect(cubit.state.selectedPlanId, isNull);
    expect(cubit.state.hasPlans, isFalse);
  });

  group('load', () {
    test('success → loaded with plans', () async {
      when(() => fetch()).thenAnswer(
        (_) async => const Right<Failure, List<SubscriptionPlan>>(_plans),
      );
      await cubit.load();
      expect(cubit.state.status, SubscriptionPlansStatus.loaded);
      expect(cubit.state.plans, _plans);
      expect(cubit.state.hasPlans, isTrue);
      expect(cubit.state.selectedPlanId, isNull);
    });

    test('failure → error status, plans stay empty', () async {
      when(() => fetch()).thenAnswer(
        (_) async => Left<Failure, List<SubscriptionPlan>>(
          ServerFailure(message: 'boom'),
        ),
      );
      await cubit.load();
      expect(cubit.state.status, SubscriptionPlansStatus.error);
      expect(cubit.state.plans, isEmpty);
    });

    test('is idempotent — a second load after success does not refetch',
        () async {
      when(() => fetch()).thenAnswer(
        (_) async => const Right<Failure, List<SubscriptionPlan>>(_plans),
      );
      await cubit.load();
      await cubit.load();
      verify(() => fetch()).called(1);
    });
  });

  group('retry', () {
    test('after an error, refetches and can succeed', () async {
      when(() => fetch()).thenAnswer(
        (_) async => Left<Failure, List<SubscriptionPlan>>(
          ServerFailure(message: 'boom'),
        ),
      );
      await cubit.load();
      expect(cubit.state.status, SubscriptionPlansStatus.error);

      when(() => fetch()).thenAnswer(
        (_) async => const Right<Failure, List<SubscriptionPlan>>(_plans),
      );
      await cubit.retry();
      expect(cubit.state.status, SubscriptionPlansStatus.loaded);
      expect(cubit.state.plans, _plans);
      verify(() => fetch()).called(2);
    });
  });

  group('select', () {
    setUp(() {
      when(() => fetch()).thenAnswer(
        (_) async => const Right<Failure, List<SubscriptionPlan>>(_plans),
      );
    });

    test('selecting a plan sets selectedPlanId', () async {
      await cubit.load();
      cubit.select(2);
      expect(cubit.state.selectedPlanId, 2);
    });

    test('selecting null (All) clears the selection', () async {
      await cubit.load();
      cubit.select(2);
      cubit.select(null);
      expect(cubit.state.selectedPlanId, isNull);
    });

    test('re-selecting the same plan does not emit a new state', () async {
      await cubit.load();
      cubit.select(1);
      final emitted = <int?>[];
      final sub = cubit.stream.listen((s) => emitted.add(s.selectedPlanId));
      cubit.select(1); // redundant — should be a no-op
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emitted, isEmpty);
    });
  });
}
