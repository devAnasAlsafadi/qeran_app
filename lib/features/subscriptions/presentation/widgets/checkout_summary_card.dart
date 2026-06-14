import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';

/// Top section of the checkout flow: plan + duration + a clean price
/// breakdown (original, discount, total). Discount lines are only
/// rendered when the user-paid price is below the list price.
class CheckoutSummaryCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final SubscriptionPricing pricing;
  final double effectivePrice;

  const CheckoutSummaryCard({
    super.key,
    required this.plan,
    required this.pricing,
    required this.effectivePrice,
  });

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final discounted = effectivePrice < pricing.price;
    final discountAmount = pricing.price - effectivePrice;
    final durationLabel =
        pricing.label(isArabic: context.locale.languageCode == 'ar') ??
            LocaleKeys.subscriptions_duration_days
                .t(context)
                .replaceFirst('{days}', '${pricing.durationDays}');

    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s20),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(plan: plan, durationLabel: durationLabel),
          const SizedBox(height: QeranSpacing.s16),
          Container(height: 1, color: QeranColors.divider),
          const SizedBox(height: QeranSpacing.s16),
          if (discounted) ...[
            _LineRow(
              label: LocaleKeys.subscriptions_original_price.t(context),
              value: '${pricing.price.toStringAsFixed(2)} $currency',
              valueColor: QeranColors.inkMuted,
              strike: true,
            ),
            const SizedBox(height: QeranSpacing.s8),
            _LineRow(
              label: LocaleKeys.subscriptions_discount.t(context),
              value: '- ${discountAmount.toStringAsFixed(2)} $currency',
              valueColor: QeranColors.gold,
            ),
            const SizedBox(height: QeranSpacing.s12),
            Container(height: 1, color: QeranColors.divider),
            const SizedBox(height: QeranSpacing.s12),
          ],
          _LineRow(
            label: LocaleKeys.subscriptions_final_price.t(context),
            value: '${effectivePrice.toStringAsFixed(2)} $currency',
            valueColor: QeranColors.wine,
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final SubscriptionPlan plan;
  final String durationLabel;
  const _Header({required this.plan, required this.durationLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: QeranColors.gold12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: QeranColors.gold,
            size: 24,
          ),
        ),
        const SizedBox(width: QeranSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.subscriptions_summary_title.t(context),
                style: QeranTypography.title.copyWith(
                  color: QeranColors.wine,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${plan.name(isArabic: context.locale.languageCode == 'ar')} · $durationLabel',
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool strike;
  final bool emphasize;

  const _LineRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.strike = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasize
        ? QeranTypography.subtitle.copyWith(color: QeranColors.wine)
        : QeranTypography.body.copyWith(color: QeranColors.inkBody);
    final valueStyle = (emphasize
            ? QeranTypography.numeric.copyWith(
                fontSize: 20,
                color: valueColor,
              )
            : QeranTypography.numeric.copyWith(color: valueColor))
        .copyWith(
      decoration: strike ? TextDecoration.lineThrough : null,
      decorationColor: strike ? QeranColors.inkMuted : null,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}
