import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_features.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_pricing.dart';

/// Rig for subscription widget tests that render SHIPPED copy.
///
/// The real translations and fonts, not a stub loader: the subscription
/// card's days ring and the purchase-success hero are fixed-size, and a stub's
/// long key names in the default test font overflow them — layout errors that
/// have nothing to do with the widget under test.
class SubscriptionDiskLoader extends AssetLoader {
  const SubscriptionDiskLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    // Synchronous: an awaited read doesn't complete inside pumpAndSettle.
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

/// Registers the two shipped families so text measures at production widths.
Future<void> loadShippedFonts() async {
  for (final entry in const {
    'NotoKufiArabic': 'assets/fonts/NotoKufiArabic-Bold.ttf',
    'Montserrat': 'assets/fonts/Montserrat-Bold.ttf',
  }.entries) {
    final bytes = File(entry.value).readAsBytesSync();
    await (FontLoader(
      entry.key,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}

/// The English string a user actually sees for `subscriptions.<key>`.
String shippedSubscriptionsEn(String key) {
  final json =
      jsonDecode(File('assets/translations/en.json').readAsStringSync())
          as Map<String, dynamic>;
  return (json['subscriptions'] as Map<String, dynamic>)[key] as String;
}

SubscriptionPlan planWith({int? seriousInterests}) => SubscriptionPlan(
  id: 1,
  nameAr: 'Gold',
  nameEn: 'Gold',
  descriptionAr: null,
  descriptionEn: null,
  icon: '',
  color: '#D4AF37',
  sortOrder: 1,
  isActive: true,
  isPopular: false,
  isFree: false,
  features: SubscriptionFeatures(
    likesAllowed: 50,
    seriousInterestsAllowed: seriousInterests,
    photoExchangesAllowed: 5,
    dailyProfileViewsAllowed: -1,
  ),
  pricings: const [],
);

CurrentSubscription subscriptionWith({
  int? allowed,
  int? used,
  int? remaining,
}) => CurrentSubscription(
  id: 7,
  plan: planWith(seriousInterests: allowed),
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
    storeProductId: null,
    appleProductId: null,
    googleProductId: null,
  ),
  startsAt: DateTime.now().subtract(const Duration(days: 1)),
  expiresAt: DateTime.now().add(const Duration(days: 60)),
  isActive: true,
  likesUsed: 12,
  likesRemaining: 38,
  seriousInterestsUsed: used,
  seriousInterestsRemaining: remaining,
  photoExchangesUsed: 0,
  photoExchangesRemaining: 5,
);

/// Pumps [body] in English with the shipped theme. [page] widgets are full
/// screens with their own Scaffold; anything else is a section, wrapped in a
/// scrolling Scaffold.
Future<void> pumpSubscriptionWidget(
  WidgetTester tester,
  Widget body, {
  bool page = false,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const SubscriptionDiskLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          theme: QeranTheme.light(ctx.locale),
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: page
              ? body
              : Scaffold(body: SingleChildScrollView(child: body)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
