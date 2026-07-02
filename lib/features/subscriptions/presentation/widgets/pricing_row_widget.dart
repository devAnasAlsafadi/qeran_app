import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/subscription_format.dart';

/// One tappable pricing option. Selected → gold border + cream fill + a filled
/// gold radio. Discounted rows show a strike-through original price + a gold
/// "خصم %" chip. All money/labels are backend-driven.
class PricingRowWidget extends StatelessWidget {
  final SubscriptionPricing pricing;
  final bool selected;
  final VoidCallback onTap;

  const PricingRowWidget({
    super.key,
    required this.pricing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
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
                    if (pricing.durationDays > 30) ...[
                      QeranSpacing.vs4,
                      Text(
                        '${pricing.monthlyEquivalent.toStringAsFixed(2)} '
                        '$currency${LocaleKeys.subscriptions_per_month.t(context)}',
                        style: QeranTypography.caption
                            .copyWith(color: QeranColors.inkMuted),
                      ),
                    ],
                  ],
                ),
              ),
              QeranSpacing.hs12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (pricing.hasStrikethroughOriginal) ...[
                        Text(
                          '${pricing.originalPrice!.toStringAsFixed(2)} $currency',
                          style: QeranTypography.bodySm.copyWith(
                            color: QeranColors.inkMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: QeranColors.inkMuted,
                          ),
                        ),
                        QeranSpacing.hs8,
                      ],
                      Text(
                        SubscriptionFormat.formatPrice(pricing.price, currency),
                        style: QeranTypography.numeric.copyWith(
                          fontSize: 18,
                          color: QeranColors.wine,
                        ),
                      ),
                    ],
                  ),
                  if (pricing.hasDiscountBadge) ...[
                    QeranSpacing.vs4,
                    QeranChip(
                      label: LocaleKeys.subscriptions_discount_badge
                          .t(context)
                          .replaceFirst('{percent}', '${pricing.discountPercent}'),
                      variant: QeranChipVariant.interest,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
