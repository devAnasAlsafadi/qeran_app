import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_selection_widget.dart';

SubscriptionPricing _pricing({
  String? labelAr,
  String? labelEn,
  int durationDays = 90,
}) =>
    SubscriptionPricing(
      id: 1,
      planId: 1,
      durationDays: durationDays,
      labelAr: labelAr,
      labelEn: labelEn,
      price: 9.99,
      originalPrice: null,
      discountPercent: 0,
      monthlyEquivalent: 9.99,
      sortOrder: 1,
      isActive: true,
      isPopular: false,
      storeProductId: null,
      appleProductId: null,
      googleProductId: null,
    );

void main() {
  group('ownedPlanBadgeLabel', () {
    test('appends the period with a middot when known', () {
      expect(ownedPlanBadgeLabel('Your plan', '3 months'),
          'Your plan · 3 months');
      expect(ownedPlanBadgeLabel('خطتك الحالية', '3 أشهر'),
          'خطتك الحالية · 3 أشهر');
    });

    test('null period → plan label alone (no fabricated period)', () {
      expect(ownedPlanBadgeLabel('Your plan', null), 'Your plan');
    });
  });

  group('SubscriptionPricing.label — owned-period source', () {
    test('picks the active-locale label', () {
      final p = _pricing(labelAr: '3 أشهر', labelEn: '3 months');
      expect(p.label(isArabic: true), '3 أشهر');
      expect(p.label(isArabic: false), '3 months');
    });

    test('falls back to the other locale when the primary is empty', () {
      final p = _pricing(labelAr: '', labelEn: '3 months');
      expect(p.label(isArabic: true), '3 months');
    });

    test('null when neither label set → caller uses {days} fallback', () {
      final p = _pricing(labelAr: null, labelEn: null);
      expect(p.label(isArabic: true), isNull);
      expect(p.label(isArabic: false), isNull);
    });
  });
}
