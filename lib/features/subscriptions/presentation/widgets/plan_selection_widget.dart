import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/entities/current_subscription.dart';
import 'plan_features_widget.dart';
import 'plan_pricing_selector.dart';

part 'plan_selection_card.dart';
part 'plan_selection_free_card.dart';

/// Owned-plan badge text: the plan label alone, or "{plan} · {period}" when the
/// owned pricing period is known. Backend-driven — [periodLabel] is null when no
/// pricing period is available, so no period is fabricated. Pure + top-level so
/// it's unit-testable without a widget.
String ownedPlanBadgeLabel(String planLabel, String? periodLabel) =>
    periodLabel == null ? planLabel : '$planLabel · $periodLabel';

class PlanSelectionWidget extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int activeIndex;
  final SubscriptionPlan activePlan;

  /// Resolves the currently-selected pricing for a given plan (the cubit's
  /// `pricingFor`). The card header price and the billing-period picker both
  /// read this, so they never diverge from the summary/CTA/charge — which
  /// read the same selection.
  final SubscriptionPricing? Function(SubscriptionPlan plan) selectedPricingFor;
  final ValueChanged<int> onPlanChanged;
  final ValueChanged<int> onPricingSelected;
  final CurrentSubscription? currentSub;

  final StoreProduct? Function(SubscriptionPricing pricing) resolveStoreProduct;

  const PlanSelectionWidget({
    super.key,
    required this.plans,
    required this.activeIndex,
    required this.activePlan,
    required this.selectedPricingFor,
    required this.onPlanChanged,
    required this.onPricingSelected,
    required this.resolveStoreProduct,
    this.currentSub,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final hasActivePaidSub = currentSub != null;
    final ownedPlanId = currentSub?.plan.id;

    // The period the user actually owns (monthly vs 3-month), resolved from the
    // owned pricing — locale label first, then the backend `{days}` fallback
    // (never fabricated). Null when nothing is owned → badge shows plan alone.
    final ownedPeriodLabel = currentSub == null
        ? null
        : currentSub!.pricing.label(isArabic: isArabic) ??
            LocaleKeys.subscriptions_duration_days
                .t(context)
                .replaceFirst('{days}', '${currentSub!.pricing.durationDays}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. FREE USER FLOW: Show Free Plan Card at top
        if (!hasActivePaidSub) ...[
          const _FreePlanCard(),
          QeranSpacing.vs20,
        ],

        // 2. PLAN CARDS LIST
        Text(
          hasActivePaidSub
              ? LocaleKeys.subscriptions_available_plans.t(context)
              : LocaleKeys.subscriptions_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.wine),
        ),
        QeranSpacing.vs12,

        Column(
          children: [
            for (int i = 0; i < plans.length; i++) ...[
              if (i > 0) QeranSpacing.vs16,
              _PlanCard(
                plan: plans[i],
                index: i,
                isSelected: i == activeIndex,
                ownedPlanId: ownedPlanId,
                ownedPeriodLabel: ownedPeriodLabel,
                isArabic: isArabic,
                selectedPricingFor: selectedPricingFor,
                resolveStoreProduct: resolveStoreProduct,
                onPlanChanged: onPlanChanged,
                onPricingSelected: onPricingSelected,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
