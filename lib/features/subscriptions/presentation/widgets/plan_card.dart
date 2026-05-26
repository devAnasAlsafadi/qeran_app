import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/subscription_format.dart';
import 'feature_row.dart';
import 'plan_visual.dart';
import 'pricing_segment.dart';

/// Premium plan card: header with icon + name + popular badge,
/// description, feature rows, pricing segmented control, price summary,
/// and a gold CTA. Popular plans gain a top gold accent bar so the
/// recommended choice carries the most visual weight on the screen.
///
/// All plan data is API-driven — never hardcoded.
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
    final isPopular = plan.isPopular;
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: isPopular ? QeranShadows.e3 : QeranShadows.e2,
        border: isPopular
            ? null
            : Border.all(color: QeranColors.wine08),
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.cardR,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPopular) Container(height: 3, color: QeranColors.gold),
            Padding(
              padding: const EdgeInsets.all(QeranSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlanHeader(plan: plan),
                  if (plan.descriptionAr != null &&
                      plan.descriptionAr!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: QeranSpacing.s8),
                      child: Text(
                        plan.descriptionAr!,
                        style: QeranTypography.bodySm,
                      ),
                    ),
                  QeranSpacing.vs16,
                  _FeatureList(plan: plan),
                  QeranSpacing.vs16,
                  _DurationLabel(),
                  QeranSpacing.vs8,
                  PricingSegment(
                    pricings: plan.activePricings,
                    selectedPricingId: selectedPricing?.id ?? -1,
                    onSelected: onSelectPricing,
                  ),
                  QeranSpacing.vs16,
                  if (selectedPricing != null)
                    _PriceSummary(pricing: selectedPricing!),
                  QeranSpacing.vs16,
                  QeranButton(
                    label:
                        LocaleKeys.subscriptions_subscribe_cta.t(context),
                    variant: QeranButtonVariant.primary,
                    onPressed: onSubscribe,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _PlanIcon(icon: plan.icon),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            plan.nameAr,
            style: QeranTypography.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (plan.isPopular) const _PopularPlanBadge(),
      ],
    );
  }
}

class _PlanIcon extends StatelessWidget {
  final String icon;
  const _PlanIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold.withValues(alpha: 0.18),
        border: Border.all(color: QeranColors.gold, width: 1),
      ),
      alignment: Alignment.center,
      child: PlanVisual.isUrl(icon)
          ? ClipOval(
              child: Image.network(
                icon,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.workspace_premium_rounded,
                  color: QeranColors.wine,
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
  const _PopularPlanBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: QeranColors.gold.withValues(alpha: 0.20),
        borderRadius: QeranRadii.pill,
        border: Border.all(color: QeranColors.gold, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 14, color: QeranColors.wine),
          QeranSpacing.hs4,
          Text(
            LocaleKeys.subscriptions_popular_plan.t(context),
            style: QeranTypography.caption
                .copyWith(color: QeranColors.wine),
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
      style: QeranTypography.caption,
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
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: QeranColors.inkMuted,
                ),
              ),
              QeranSpacing.hs8,
            ],
            Text(
              '${pricing.price.toStringAsFixed(2)} $currency',
              style: QeranTypography.numeric.copyWith(
                fontSize: 22,
                color: QeranColors.wine,
              ),
            ),
            const Spacer(),
            if (pricing.hasDiscountBadge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s12,
                  vertical: QeranSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: QeranColors.gold.withValues(alpha: 0.20),
                  borderRadius: QeranRadii.pill,
                ),
                child: Text(
                  '${pricing.discountPercent}%',
                  style: QeranTypography.label,
                ),
              ),
          ],
        ),
        if (pricing.durationDays > 30) ...[
          QeranSpacing.vs4,
          Text(
            '${pricing.monthlyEquivalent.toStringAsFixed(2)} $currency'
            '${LocaleKeys.subscriptions_per_month.t(context)}',
            style: QeranTypography.caption,
          ),
        ],
      ],
    );
  }
}
