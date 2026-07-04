import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';

void main() {
  group('SubscriptionFeatures.isUnlimited', () {
    test('returns true only for the -1 sentinel', () {
      expect(SubscriptionFeatures.isUnlimited(-1), isTrue);
      expect(SubscriptionFeatures.isUnlimited(0), isFalse);
      expect(SubscriptionFeatures.isUnlimited(50), isFalse);
      expect(SubscriptionFeatures.isUnlimited(2147483647), isFalse);
    });
  });

  group('CurrentSubscription.isUnlimitedRemaining', () {
    test('returns true only for int.MaxValue', () {
      expect(
        CurrentSubscription.isUnlimitedRemaining(2147483647),
        isTrue,
      );
      expect(CurrentSubscription.isUnlimitedRemaining(-1), isFalse);
      expect(CurrentSubscription.isUnlimitedRemaining(0), isFalse);
      expect(CurrentSubscription.isUnlimitedRemaining(38), isFalse);
    });
  });

  group('SubscriptionPricing.hasStrikethroughOriginal', () {
    SubscriptionPricing make({double? originalPrice, double price = 26.99}) =>
        SubscriptionPricing(
          id: 12,
          planId: 1,
          durationDays: 90,
          labelAr: '3 أشهر',
          labelEn: null,
          price: price,
          originalPrice: originalPrice,
          discountPercent: 10,
          monthlyEquivalent: 8.99,
          sortOrder: 1,
          isActive: true,
          isPopular: false,
          storeProductId: null,
          appleProductId: null,
          googleProductId: null,
        );

    test('false when originalPrice is null', () {
      expect(make(originalPrice: null).hasStrikethroughOriginal, isFalse);
    });
    test('false when originalPrice == price', () {
      expect(
        make(originalPrice: 26.99).hasStrikethroughOriginal,
        isFalse,
      );
    });
    test('false when originalPrice < price', () {
      expect(make(originalPrice: 20).hasStrikethroughOriginal, isFalse);
    });
    test('true when originalPrice > price', () {
      expect(
        make(originalPrice: 29.97).hasStrikethroughOriginal,
        isTrue,
      );
    });
  });

  group('SubscriptionPricing.hasDiscountBadge', () {
    SubscriptionPricing make(int discountPercent) => SubscriptionPricing(
          id: 12,
          planId: 1,
          durationDays: 30,
          labelAr: null,
          labelEn: null,
          price: 9.99,
          originalPrice: null,
          discountPercent: discountPercent,
          monthlyEquivalent: 9.99,
          sortOrder: 0,
          isActive: true,
          isPopular: false,
          storeProductId: null,
          appleProductId: null,
          googleProductId: null,
        );

    test('false at 0', () => expect(make(0).hasDiscountBadge, isFalse));
    test('true at 1', () => expect(make(1).hasDiscountBadge, isTrue));
    test('true at 25', () => expect(make(25).hasDiscountBadge, isTrue));
  });
}
