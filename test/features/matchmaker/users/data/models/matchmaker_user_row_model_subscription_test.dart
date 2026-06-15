import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/users/data/models/matchmaker_user_row_model.dart';

/// Focused on the Step A addition: the stable `subscription.planId` key used
/// for cross-locale plan filtering under the مشتركون tab.
void main() {
  group('MatchmakerUserRowModel — subscription.planId', () {
    test('subscribed row carries planId + planName + expiry', () {
      final entity = MatchmakerUserRowModel.fromJson({
        'userId': 'guid',
        'fullName': 'TEST3',
        'subscription': {
          'planId': 2,
          'planName': 'الباقة الذهبية',
          'expiresAt': '2027-06-04T00:00:00Z',
        },
      }).toEntity();

      expect(entity.subscriptionPlanId, 2);
      expect(entity.subscriptionPlanName, 'الباقة الذهبية');
      expect(entity.subscriptionExpiresAt, isNotNull);
      expect(entity.isSubscribed, isTrue);
    });

    test('planId tolerates a string value (int↔string drift)', () {
      final entity = MatchmakerUserRowModel.fromJson({
        'userId': 'guid',
        'fullName': 'test2',
        'subscription': {'planId': '7', 'planName': 'البريميوم'},
      }).toEntity();

      expect(entity.subscriptionPlanId, 7);
    });

    test('non-subscribed row (no subscription map) → planId null', () {
      final entity = MatchmakerUserRowModel.fromJson({
        'userId': 'guid',
        'fullName': 'Arwa',
      }).toEntity();

      expect(entity.subscriptionPlanId, isNull);
      expect(entity.subscriptionPlanName, isNull);
      expect(entity.isSubscribed, isFalse);
    });
  });
}
