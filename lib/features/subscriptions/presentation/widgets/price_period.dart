import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';

/// A store price with the period it pays for, "SAR 99.99 / 3 أشهر" (run 10).
/// Never a fixed «/شهر»: a three-month price is three months.
String priceWithPeriod(
  BuildContext context,
  StoreProduct product,
  SubscriptionPricing pricing,
) => LocaleKeys.subscriptions_price_per_period.t(
  context,
  namedArgs: {
    'price': product.priceString,
    'period': pricePeriod(context, pricing, product),
  },
);

/// The period in words: the store's own `subscriptionPeriod` first (ISO 8601,
/// `P1M`, `P3M`, `P1Y`: what the store charges for), else the dashboard's
/// period label, else its days.
String pricePeriod(
  BuildContext context,
  SubscriptionPricing pricing,
  StoreProduct? product,
) =>
    _storePeriod(context, product?.subscriptionPeriod) ??
    pricing.label(isArabic: context.locale.languageCode == 'ar') ??
    LocaleKeys.subscriptions_duration_days
        .t(context)
        .replaceFirst('{days}', '${pricing.durationDays}');

final RegExp _iso = RegExp('^P([0-9]+)([DWMY])\$');

String? _storePeriod(BuildContext context, String? iso) {
  final match = _iso.firstMatch(iso ?? '');
  if (match == null) return null;
  final key = switch (match.group(2)) {
    'D' => LocaleKeys.subscriptions_period_day,
    'W' => LocaleKeys.subscriptions_period_week,
    'M' => LocaleKeys.subscriptions_period_month,
    _ => LocaleKeys.subscriptions_period_year,
  };
  return key.tPlural(context, int.parse(match.group(1)!));
}
