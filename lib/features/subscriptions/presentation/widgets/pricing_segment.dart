import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
      spacing: AppDimens.p8,
      runSpacing: AppDimens.p8,
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
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.18),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? AppColors.white : AppColors.textPrimary,
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
            ? AppColors.white.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocaleKeys.subscriptions_popular_pricing.t(context),
        style: AppTextStyles.labelSmall.copyWith(
          color: selected ? AppColors.white : AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
