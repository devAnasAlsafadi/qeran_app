import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/plans/subscription_plans_state.dart';

SubscriptionPlan _plan({required int id, required bool isFree, int? tier}) =>
    SubscriptionPlan(
      id: id,
      nameAr: '',
      nameEn: 'P$id',
      descriptionAr: null,
      descriptionEn: null,
      icon: '',
      color: '',
      sortOrder: id,
      isActive: true,
      isPopular: false,
      isFree: isFree,
      tier: tier,
      features: const SubscriptionFeatures(
        likesAllowed: 0,
        seriousInterestsAllowed: 0,
        photoExchangesAllowed: 0,
        dailyProfileViewsAllowed: 0,
      ),
      pricings: const [],
    );

void main() {
  group('SubscriptionPlansLoaded.paidPlans', () {
    test('filters the free plan out, preserving paid order (no duplicate free)',
        () {
      final state = SubscriptionPlansLoaded(
        plans: [
          _plan(id: 0, isFree: true, tier: 0),
          _plan(id: 1, isFree: false, tier: 1),
          _plan(id: 2, isFree: false, tier: 2),
        ],
        selectionByPlan: const {},
      );

      expect(state.paidPlans.map((p) => p.id), [1, 2]);
      expect(state.paidPlans.any((p) => p.isFree), isFalse);
    });

    test('no free plan → list unchanged', () {
      final state = SubscriptionPlansLoaded(
        plans: [
          _plan(id: 1, isFree: false, tier: 1),
          _plan(id: 2, isFree: false, tier: 2),
        ],
        selectionByPlan: const {},
      );

      expect(state.paidPlans.map((p) => p.id), [1, 2]);
    });

    test('only the free plan → empty (screen guards on this)', () {
      final state = SubscriptionPlansLoaded(
        plans: [_plan(id: 0, isFree: true, tier: 0)],
        selectionByPlan: const {},
      );

      expect(state.paidPlans, isEmpty);
    });
  });
}
