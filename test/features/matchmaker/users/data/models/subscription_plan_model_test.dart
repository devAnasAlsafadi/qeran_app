import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/users/data/models/subscription_plan_model.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/subscription_plan.dart';

void main() {
  group('SubscriptionPlanModel — parsing', () {
    test('full payload parses planId/names/count; ignores icon + color', () {
      final entity = SubscriptionPlanModel.fromJson({
        'planId': 2,
        'nameAr': 'الباقة الذهبية',
        'nameEn': 'Gold Plan',
        'icon': 'crown',
        'color': '#D4AF37',
        'subscriberCount': 5,
      }).toEntity();

      expect(entity.planId, 2);
      expect(entity.nameAr, 'الباقة الذهبية');
      expect(entity.nameEn, 'Gold Plan');
      expect(entity.subscriberCount, 5);
      // icon/color are intentionally not on the entity — nothing to assert,
      // their absence is the contract.
    });

    test('tolerates numbers-as-strings (int↔string drift)', () {
      final entity = SubscriptionPlanModel.fromJson({
        'planId': '7',
        'nameAr': 'البريميوم',
        'nameEn': 'Premium',
        'subscriberCount': '12',
      }).toEntity();

      expect(entity.planId, 7);
      expect(entity.subscriberCount, 12);
    });

    test('missing fields fall back (planId 0, count 0, empty names)', () {
      final entity =
          SubscriptionPlanModel.fromJson(<String, dynamic>{}).toEntity();

      expect(entity.planId, 0);
      expect(entity.nameAr, '');
      expect(entity.nameEn, '');
      expect(entity.subscriberCount, 0);
    });
  });

  group('SubscriptionPlan.name — locale pick + fallback', () {
    const plan = SubscriptionPlan(
      planId: 1,
      nameAr: 'الباقة الذهبية',
      nameEn: 'Gold Plan',
      subscriberCount: 3,
    );

    test('arabic picks nameAr', () {
      expect(plan.name(isArabic: true), 'الباقة الذهبية');
    });

    test('english picks nameEn', () {
      expect(plan.name(isArabic: false), 'Gold Plan');
    });

    test('falls back to the other locale when primary is empty', () {
      const arOnly = SubscriptionPlan(
        planId: 1,
        nameAr: 'الباقة الذهبية',
        nameEn: '',
        subscriberCount: 0,
      );
      expect(arOnly.name(isArabic: false), 'الباقة الذهبية');
    });
  });
}
