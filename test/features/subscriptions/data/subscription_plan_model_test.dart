import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';

void main() {
  group('SubscriptionPlanModel.fromJson — tier', () {
    test('parses tier and carries it through toEntity', () {
      final model = SubscriptionPlanModel.fromJson({
        'id': 3,
        'nameEn': 'VIP',
        'nameAr': 'الذهبية',
        'tier': 2,
      });
      expect(model.tier, 2);

      final entity = model.toEntity();
      expect(entity.tier, 2);
      expect(entity.isVipTier, isTrue);
      expect(entity.isBasicTier, isFalse);
    });

    test('absent tier → null → identified as no tier', () {
      final model = SubscriptionPlanModel.fromJson({'id': 1, 'nameEn': 'Legacy'});
      expect(model.tier, isNull);

      final entity = model.toEntity();
      expect(entity.tier, isNull);
      expect(entity.isVipTier, isFalse);
      expect(entity.isBasicTier, isFalse);
    });

    test('tier as num (e.g. 1.0) coerces to int', () {
      final model = SubscriptionPlanModel.fromJson({'id': 2, 'tier': 1.0});
      expect(model.tier, 1);
      expect(model.toEntity().isBasicTier, isTrue);
    });
  });

  group('SubscriptionPlan tier getters', () {
    SubscriptionPlan planWithTier(int? tier) => SubscriptionPlan(
          id: 1,
          nameAr: '',
          nameEn: '',
          descriptionAr: null,
          descriptionEn: null,
          icon: '',
          color: '',
          sortOrder: 0,
          isActive: true,
          isPopular: false,
          isFree: tier == 0,
          tier: tier,
          features: const SubscriptionFeatures(
            likesAllowed: 0,
            seriousInterestsAllowed: 0,
            photoExchangesAllowed: 0,
            dailyProfileViewsAllowed: 0,
          ),
          pricings: const [],
        );

    test('tier 2 → VIP only', () {
      expect(planWithTier(2).isVipTier, isTrue);
      expect(planWithTier(2).isBasicTier, isFalse);
    });

    test('tier 1 → Basic only', () {
      expect(planWithTier(1).isBasicTier, isTrue);
      expect(planWithTier(1).isVipTier, isFalse);
    });

    test('tier 0 and null → neither VIP nor Basic (not exhaustive)', () {
      expect(planWithTier(0).isVipTier, isFalse);
      expect(planWithTier(0).isBasicTier, isFalse);
      expect(planWithTier(null).isVipTier, isFalse);
      expect(planWithTier(null).isBasicTier, isFalse);
    });
  });
}
