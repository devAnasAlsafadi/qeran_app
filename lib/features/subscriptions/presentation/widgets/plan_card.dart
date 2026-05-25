import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/subscription_format.dart';
import 'feature_row.dart';
import 'plan_visual.dart';
import 'pricing_segment.dart';

/// Premium plan card: header with icon+name+popular badge, description,
/// feature rows, pricing segmented control, price summary, CTA.
///
/// All visuals are derived from the API — never hardcode plan IDs,
/// names, or prices.
class PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final SubscriptionPricing? selectedPricing;
  final ValueChanged<int> onSelectPricing;
  final VoidCallback? onSubscribe;

  const PlanCard({
    super.key,
    required this.plan,
    required this.selectedPricing,
    required this.onSelectPricing,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PlanVisual.parseColor(plan.color);
    return Container(
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14431C33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlanHeader(plan: plan, accent: accent),
          if (plan.descriptionAr != null && plan.descriptionAr!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.p8),
              child: Text(
                plan.descriptionAr!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: AppDimens.p16),
          _FeatureList(plan: plan),
          const SizedBox(height: AppDimens.p16),
          _DurationLabel(),
          const SizedBox(height: AppDimens.p8),
          PricingSegment(
            pricings: plan.activePricings,
            selectedPricingId: selectedPricing?.id ?? -1,
            onSelected: onSelectPricing,
          ),
          const SizedBox(height: AppDimens.p16),
          if (selectedPricing != null) _PriceSummary(pricing: selectedPricing!),
          const SizedBox(height: AppDimens.p16),
          CustomButton(
            text: LocaleKeys.subscriptions_subscribe_cta.t(context),
            backgroundColor: AppColors.primary,
            onPressed: onSubscribe,
          ),
        ],
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color accent;
  const _PlanHeader({required this.plan, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PlanIcon(icon: plan.icon, accent: accent),
        const SizedBox(width: AppDimens.p12),
        Expanded(
          child: Text(
            plan.nameAr,
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (plan.isPopular) _PopularPlanBadge(accent: accent),
      ],
    );
  }
}

class _PlanIcon extends StatelessWidget {
  final String icon;
  final Color accent;
  const _PlanIcon({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: PlanVisual.isUrl(icon)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                icon,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.workspace_premium_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
            )
          : Text(
              icon.isEmpty ? '💎' : icon,
              style: const TextStyle(fontSize: 22),
            ),
    );
  }
}

class _PopularPlanBadge extends StatelessWidget {
  final Color accent;
  const _PopularPlanBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            LocaleKeys.subscriptions_popular_plan.t(context),
            style: AppTextStyles.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final SubscriptionPlan plan;
  const _FeatureList({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FeatureRow(
          icon: Icons.favorite_rounded,
          label: LocaleKeys.subscriptions_feature_likes_label.t(context),
          value: SubscriptionFormat.formatAllowed(
            context,
            plan.features.likesAllowed,
            LocaleKeys.subscriptions_feature_likes.t(context),
          ),
        ),
        FeatureRow(
          icon: Icons.photo_camera_rounded,
          label: LocaleKeys.subscriptions_feature_photo_exchanges_label
              .t(context),
          value: SubscriptionFormat.formatAllowed(
            context,
            plan.features.photoExchangesAllowed,
            LocaleKeys.subscriptions_feature_photo_exchanges.t(context),
          ),
        ),
        FeatureRow(
          icon: Icons.workspace_premium_rounded,
          label: LocaleKeys.subscriptions_feature_serious_interests_label
              .t(context),
          value: SubscriptionFormat.formatAllowed(
            context,
            plan.features.seriousInterestsAllowed,
            LocaleKeys.subscriptions_feature_serious_interests.t(context),
          ),
        ),
        FeatureRow(
          icon: Icons.visibility_rounded,
          label: LocaleKeys.subscriptions_feature_daily_profile_views_label
              .t(context),
          value: SubscriptionFormat.formatAllowed(
            context,
            plan.features.dailyProfileViewsAllowed,
            LocaleKeys.subscriptions_feature_daily_profile_views.t(context),
          ),
        ),
      ],
    );
  }
}

class _DurationLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.subscriptions_select_duration.t(context),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final SubscriptionPricing pricing;
  const _PriceSummary({required this.pricing});

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (pricing.hasStrikethroughOriginal) ...[
              Text(
                '${pricing.originalPrice!.toStringAsFixed(2)} $currency',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppDimens.p8),
            ],
            Text(
              '${pricing.price.toStringAsFixed(2)} $currency',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (pricing.hasDiscountBadge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pricing.discountPercent}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        if (pricing.durationDays > 30) ...[
          const SizedBox(height: 4),
          Text(
            '${pricing.monthlyEquivalent.toStringAsFixed(2)} $currency'
            '${LocaleKeys.subscriptions_per_month.t(context)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
