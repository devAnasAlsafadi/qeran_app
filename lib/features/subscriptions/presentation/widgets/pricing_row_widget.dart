import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_skeleton.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';

/// One tappable pricing option (selected → gold border + cream fill + filled
/// radio). The store's localized `priceString` is the only price ever shown.
///
/// There is no backend-price fallback: the backend `price` is administrative
/// and differs from what the store charges, so it would misstate the amount
/// being billed. Until the catalogue answers the row shows a placeholder
/// ([storeResolved] false); afterwards, a product with no store entry reads as
/// unavailable. The backend-currency extras (per-month subtitle,
/// strike-through, discount badge) go with it — they are in the same
/// mismatched units.
class PricingRowWidget extends StatelessWidget {
  final SubscriptionPricing pricing;
  final StoreProduct? storeProduct;

  /// False while the store catalogue is still in flight.
  final bool storeResolved;
  final bool selected;
  final VoidCallback onTap;

  const PricingRowWidget({
    super.key,
    required this.pricing,
    required this.storeProduct,
    required this.storeResolved,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        pricing.label(isArabic: context.locale.languageCode == 'ar') ??
            LocaleKeys.subscriptions_duration_days
                .t(context)
                .replaceFirst('{days}', '${pricing.durationDays}');
    return Material(
      color: selected ? QeranColors.creamSurface : QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.controlR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.controlR,
            border: Border.all(
              color: selected ? QeranColors.gold : QeranColors.wine08,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: QeranTypography.subtitle
                          .copyWith(color: QeranColors.wine),
                    ),
                  ],
                ),
              ),
              QeranSpacing.hs12,
              _PriceCluster(
                storeProduct: storeProduct,
                storeResolved: storeResolved,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trailing price block: the store `priceString`, a shimmer while the
/// catalogue loads, or an "unavailable" note once it has answered without one.
/// Price text is pinned `TextDirection.ltr` so a Latin store string
/// ("SAR 50.00") never RTL-reorders.
class _PriceCluster extends StatelessWidget {
  final StoreProduct? storeProduct;
  final bool storeResolved;

  const _PriceCluster({
    required this.storeProduct,
    required this.storeResolved,
  });

  @override
  Widget build(BuildContext context) {
    final store = storeProduct;
    if (store != null) return _priceText(store.priceString);
    if (!storeResolved) return const QeranSkeleton.box(width: 72, height: 18);
    return Text(
      LocaleKeys.subscriptions_purchase_package_not_found.t(context),
      textAlign: TextAlign.end,
      style: QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
    );
  }

  Widget _priceText(String text) => Text(
        text,
        textDirection: TextDirection.ltr,
        style: QeranTypography.numeric.copyWith(
          fontSize: 18,
          color: QeranColors.wine,
        ),
      );
}

/// Custom radio — gold-filled when selected, wine-outlined otherwise. Avoids
/// the Material radio's grey/blue ripple so the surface stays on-brand.
class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.gold : QeranColors.wine20,
          width: selected ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.gold,
              ),
            )
          : null,
    );
  }
}
