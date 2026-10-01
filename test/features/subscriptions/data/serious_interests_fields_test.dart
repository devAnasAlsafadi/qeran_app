import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/data/models/current_subscription_model.dart';
import 'package:qeran/features/subscriptions/data/models/subscription_features_model.dart';

/// The backend drops the three `seriousInterests*` fields from the JSON on
/// release day (absent, not null). Parsing must survive that, and must not
/// turn the absence into a 0 the screens would then draw as a real allowance.
void main() {
  group('SubscriptionFeaturesModel — seriousInterestsAllowed', () {
    const base = {
      'likesAllowed': 50,
      'photoExchangesAllowed': 5,
      'dailyProfileViewsAllowed': -1,
    };

    test('absent → null on the model and the entity', () {
      final model = SubscriptionFeaturesModel.fromJson(base);

      expect(model.seriousInterestsAllowed, isNull);
      expect(model.toEntity().seriousInterestsAllowed, isNull);
      expect(model.toEntity().likesAllowed, 50);
    });

    test('present → its value, the unlimited sentinel included', () {
      final some = SubscriptionFeaturesModel.fromJson({
        ...base,
        'seriousInterestsAllowed': 3,
      });
      final unlimited = SubscriptionFeaturesModel.fromJson({
        ...base,
        'seriousInterestsAllowed': -1,
      });

      expect(some.toEntity().seriousInterestsAllowed, 3);
      expect(unlimited.toEntity().seriousInterestsAllowed, -1);
    });
  });

  group('CurrentSubscriptionModel — seriousInterests counters', () {
    const base = {
      'id': 7,
      'expiresAt': '2026-12-01T00:00:00Z',
      'likesUsed': 12,
      'likesRemaining': 38,
      'photoExchangesUsed': 0,
      'photoExchangesRemaining': 5,
    };

    test('absent → both null on the model and the entity', () {
      final entity = CurrentSubscriptionModel.fromJson(base).toEntity();

      expect(entity.seriousInterestsUsed, isNull);
      expect(entity.seriousInterestsRemaining, isNull);
      expect(entity.likesRemaining, 38);
    });

    test('present → their values', () {
      final entity = CurrentSubscriptionModel.fromJson({
        ...base,
        'seriousInterestsUsed': 2,
        'seriousInterestsRemaining': -1,
      }).toEntity();

      expect(entity.seriousInterestsUsed, 2);
      expect(entity.seriousInterestsRemaining, -1);
    });
  });
}
