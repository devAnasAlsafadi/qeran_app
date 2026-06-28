import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_pricing.dart';

/// Horizontal segmented control of a plan's active pricings. Tapping
/// a chip notifies the parent via [onSelected] — the parent owns the
/// "selected pricingId" state via [SubscriptionPlansCubit].
class PricingSegment extends StatelessWidget {
  final List<SubscriptionPricing> pricings;
  final int selectedPricingId;
  final ValueChanged<int> onSelected;

  const PricingSegment({
    super.key,
    required this.pricings,
    required this.selectedPricingId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: QeranSpacing.s8,
      runSpacing: QeranSpacing.s8,
      children: pricings
          .map((p) => _PricingChip(
                pricing: p,
                selected: p.id == selectedPricingId,
                onTap: () => onSelected(p.id),
              ))
          .toList(growable: false),
    );
  }
}

class _PricingChip extends StatelessWidget {
  final SubscriptionPricing pricing;
  final bool selected;
  final VoidCallback onTap;

  const _PricingChip({
    required this.pricing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = pricing.labelAr ??
        pricing.labelEn ??
        LocaleKeys.subscriptions_duration_days.t(context).replaceFirst(
              '{days}',
              '${pricing.durationDays}',
            );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? QeranColors.wine
                : QeranColors.wine.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? QeranColors.wine
                  : QeranColors.wine.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (pricing.isPopular) ...[
                _PopularPricingBadge(selected: selected),
                const SizedBox(height: 4),
              ],
              Text(
                label,
                style: QeranTypography.body.copyWith(
                  color: selected ? QeranColors.paper : QeranColors.inkStrong,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularPricingBadge extends StatelessWidget {
  final bool selected;
  const _PopularPricingBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected
            ? QeranColors.paper.withValues(alpha: 0.18)
            : QeranColors.wine.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocaleKeys.subscriptions_popular_pricing.t(context),
        style: QeranTypography.caption.copyWith(
          color: selected ? QeranColors.paper : QeranColors.wine,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
