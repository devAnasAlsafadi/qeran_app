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
import 'plan_features_widget.dart';
import 'pricing_row_widget.dart';

/// The plan + pricing selection area: a segmented plan switcher (hidden for a
/// single plan), the section title, the active plan's [PlanFeaturesWidget], and
/// one [PricingRowWidget] per active pricing. Selection is driven by the caller
/// via [onPlanChanged] / [onPricingSelected] so the cubit stays the source of
/// truth.
class PlanSelectionWidget extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int activeIndex;
  final SubscriptionPlan activePlan;
  final int? selectedPricingId;
  final ValueChanged<int> onPlanChanged;
  final ValueChanged<int> onPricingSelected;

  /// Resolves the store product backing a pricing (null ⇒ backend-price
  /// fallback). Supplied by the screen from the loaded state so this widget
  /// stays free of bloc/state coupling.
  final StoreProduct? Function(SubscriptionPricing pricing) resolveStoreProduct;

  const PlanSelectionWidget({
    super.key,
    required this.plans,
    required this.activeIndex,
    required this.activePlan,
    required this.selectedPricingId,
    required this.onPlanChanged,
    required this.onPricingSelected,
    required this.resolveStoreProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plans.length > 1) ...[
          _PlanTabs(
            plans: plans,
            activeIndex: activeIndex,
            onChanged: onPlanChanged,
          ),
          QeranSpacing.vs24,
        ],
        Text(
          LocaleKeys.subscriptions_title.t(context),
          style: QeranTypography.title.copyWith(color: QeranColors.wine),
        ),
        QeranSpacing.vs12,
        PlanFeaturesWidget(plan: activePlan),
        QeranSpacing.vs20,
        for (final pricing in activePlan.activePricings)
          Padding(
            padding: const EdgeInsets.only(bottom: QeranSpacing.s12),
            child: PricingRowWidget(
              pricing: pricing,
              storeProduct: resolveStoreProduct(pricing),
              selected: pricing.id == selectedPricingId,
              onTap: () => onPricingSelected(pricing.id),
            ),
          ),
      ],
    );
  }
}

/// Segmented control (e.g. العادي / VIP) — paper card with an animated gold
/// underline that slides correctly in RTL + LTR.
class _PlanTabs extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _PlanTabs({
    required this.plans,
    required this.activeIndex,
    required this.onChanged,
  });

  static const Duration animDuration = Duration(milliseconds: 280);
  static const double _barHeight = 3.0;
  static const double _barWidth = 40.0;
  static const double _cardHeight = 56.0;
  static const double _innerPad = 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.wine08),
        boxShadow: QeranShadows.e2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_innerPad),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellWidth = constraints.maxWidth / plans.length;
            final barStart =
                activeIndex * cellWidth + (cellWidth - _barWidth) / 2;
            return Stack(
              children: [
                AnimatedPositionedDirectional(
                  duration: animDuration,
                  curve: Curves.easeOutCubic,
                  start: barStart,
                  bottom: 6,
                  width: _barWidth,
                  height: _barHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: QeranColors.gold,
                      borderRadius: QeranRadii.pill,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < plans.length; i++)
                      Expanded(
                        child: _PlanTabCell(
                          label: plans[i].name(
                            isArabic: context.locale.languageCode == 'ar',
                          ),
                          isActive: i == activeIndex,
                          onTap: () => onChanged(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanTabCell extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PlanTabCell({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: _PlanTabs.animDuration,
          curve: Curves.easeOutCubic,
          style: QeranTypography.subtitle.copyWith(
            color: isActive ? QeranColors.wine : QeranColors.inkMuted,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
