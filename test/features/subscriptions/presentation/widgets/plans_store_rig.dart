import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/plan_selection_widget.dart';

import '../../../../core/shipped_strings_rig.dart';

/// The plans list as the live API sends it today (run 9's read), with store
/// products on demand: for the run 10 rules (the period, no API price).

SubscriptionPricing pricingOf({
  required int id,
  int planId = 5,
  int days = 30,
  String? labelAr,
  String? labelEn,
  double price = 50,
  bool isPopular = false,
  String? productId,
}) => SubscriptionPricing(
  id: id,
  planId: planId,
  durationDays: days,
  labelAr: labelAr,
  labelEn: labelEn,
  price: price,
  originalPrice: null,
  discountPercent: 0,
  monthlyEquivalent: price,
  sortOrder: id,
  isActive: true,
  isPopular: isPopular,
  storeProductId: productId,
  appleProductId: productId,
  googleProductId: productId,
);

final vipMonth = pricingOf(
  id: 9,
  labelAr: 'شهر',
  labelEn: 'Month',
  productId: 'qeran_vip_monthly',
);

final vipQuarter = pricingOf(
  id: 10,
  days: 90,
  labelAr: '3 شهور',
  labelEn: '3 months',
  price: 120,
  isPopular: true,
  productId: 'qeran_vip_3month',
);

const unlimited = SubscriptionFeatures(
  likesAllowed: -1,
  photoExchangesAllowed: -1,
  dailyProfileViewsAllowed: -1,
);

SubscriptionPlan planOf({
  int id = 5,
  String nameAr = 'الباقة الذهبية',
  String nameEn = 'VIP',
  int? tier = 2,
  bool isPopular = true,
  bool isFree = false,
  SubscriptionFeatures features = unlimited,
  List<SubscriptionPricing>? pricings,
}) => SubscriptionPlan(
  id: id,
  nameAr: nameAr,
  nameEn: nameEn,
  descriptionAr: null,
  descriptionEn: null,
  icon: '',
  color: '',
  sortOrder: id,
  isActive: true,
  isPopular: isPopular,
  isFree: isFree,
  tier: tier,
  featuresAr: 'متابعة مكثفة من الخطّابة',
  featuresEn: 'Intensive matchmaker follow-up',
  features: features,
  pricings: pricings ?? [vipMonth, vipQuarter],
);

StoreProduct productOf(String id, String price, {String? period}) =>
    StoreProduct(id, '', '', 0, price, 'SAR', subscriptionPeriod: period);

/// The plans list in [locale] at 400 wide, [selected] picked on the first
/// plan; [products] answer by product id, as the screen's lookup does.
Future<BuildContext> pumpPlans(
  WidgetTester tester,
  Locale locale, {
  List<SubscriptionPlan>? plans,
  SubscriptionPricing? selected,
  Map<String, StoreProduct> products = const {},
  bool storeResolved = true,
  SubscriptionPlan? freePlan,
}) {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final list = plans ?? [planOf()];
  return pumpShippedStrings(
    tester,
    locale,
    settle: storeResolved,
    // The theme picks the shipped font for the locale.
    builder: (_, child) => Theme(data: QeranTheme.light(locale), child: child!),
    child: Scaffold(
      body: SingleChildScrollView(
        child: PlanSelectionWidget(
          plans: list,
          activeIndex: 0,
          activePlan: list.first,
          selectedPricingFor: (plan) =>
              plan == list.first ? selected ?? vipQuarter : null,
          onPlanChanged: (_) {},
          onPricingSelected: (_) {},
          resolveStoreProduct: (p) => products[p.googleProductId],
          storeResolved: storeResolved,
          freePlan: freePlan,
        ),
      ),
    ),
  );
}
