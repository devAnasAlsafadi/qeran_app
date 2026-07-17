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
              _buildPlanCard(context, i, plans[i], ownedPlanId, isArabic),
            ],
          ],
        ),
      ],
    );
  }

  /// Plan-card price summary. Zero-price (free) plans read "مجاني"/"Free" with
  /// no currency at all; paid plans use the localized store price when it
  /// resolves, otherwise the currency token ("$") + amount. Never "SAR".
  String _priceLabel(
    BuildContext context,
    SubscriptionPricing? pricing,
    StoreProduct? storeProduct,
  ) {
    if (pricing == null) return '';
    if (pricing.price == 0) {
      return LocaleKeys.subscriptions_price_free.t(context);
    }
    if (storeProduct != null) return storeProduct.priceString;
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final price = pricing.price;
    final amount = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '$currency $amount';
  }

  Widget _buildPlanCard(
    BuildContext context,
    int index,
    SubscriptionPlan plan,
    int? ownedPlanId,
    bool isArabic,
  ) {
    final isOwned = plan.id == ownedPlanId;
    final isSelected = index == activeIndex;
    
    // Check if it's the VIP plan to show popular tag
    final isVip = plan.name(isArabic: false).toLowerCase() == 'vip';

    // Plan-card price: bound to the SELECTED pricing (the same one the summary,
    // CTA and charge read) — falling back to the first active pricing before a
    // selection exists. Free → "مجاني"/"Free" (no currency); paid → the store
    // price when resolved, else the currency token — never a hardcoded "SAR".
    final activePricings = plan.activePricings;
    final selectedPricing = selectedPricingFor(plan) ??
        (activePricings.isNotEmpty ? activePricings.first : null);
    final storeProduct =
        selectedPricing != null ? resolveStoreProduct(selectedPricing) : null;
    final priceText = _priceLabel(context, selectedPricing, storeProduct);
    // A free plan reads just "مجاني" — no "/شهريًا" per-month suffix.
    final isFreePlan = selectedPricing?.price == 0;

    return GestureDetector(
      onTap: isOwned ? null : () => onPlanChanged(index),
      child: Container(
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.cardR,
          border: Border.all(
            color: isOwned
                ? QeranColors.gold.withValues(alpha: 0.40)
                : (isSelected
                    ? QeranColors.gold
                    : QeranColors.wine.withValues(alpha: 0.08)),
            width: isSelected || isOwned ? 1.8 : 1.0,
          ),
          boxShadow: isSelected || isOwned ? QeranShadows.e2 : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header of Plan Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isOwned)
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? QeranColors.gold : QeranColors.inkMuted,
                      size: 20,
                    ),
                  if (isOwned)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: QeranColors.goldDeep,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              plan.name(isArabic: isArabic),
                              style: QeranTypography.subtitle.copyWith(
                                color: QeranColors.wine,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isVip) ...[
                              QeranSpacing.hs8,
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: QeranColors.gold.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  LocaleKeys.subscriptions_badge_popular.t(context),
                                  style: QeranTypography.bodySm.copyWith(
                                    fontSize: 10,
                                    color: QeranColors.goldDeep,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (priceText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            isFreePlan
                                ? priceText
                                : '$priceText ${LocaleKeys.subscriptions_per_month.t(context)}',
                            style: QeranTypography.bodySm.copyWith(
                              color: QeranColors.inkBody,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Badges (Current / Upgrade Available)
                  if (isOwned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: QeranColors.wine.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        LocaleKeys.subscriptions_badge_your_plan.t(context),
                        style: QeranTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: QeranColors.wine,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (!isOwned && ownedPlanId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: QeranColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        LocaleKeys.subscriptions_badge_upgrade_available.t(context),
                        style: QeranTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: QeranColors.goldDeep,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Billing-period picker — sits directly under the header price,
              // above the features. Only for a purchase candidate (selected,
              // not owned) that exposes more than one pricing; a single-pricing
              // plan (e.g. Basic) shows nothing.
              if (isSelected && !isOwned && activePricings.length > 1) ...[
                QeranSpacing.vs12,
                PlanPricingSelector(
                  plan: plan,
                  selectedPricingId: selectedPricing?.id,
                  resolveStoreProduct: resolveStoreProduct,
                  onPricingSelected: onPricingSelected,
                ),
              ],

              // Expanded Features list (only when selected or owned)
              if (isSelected || isOwned) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: QeranColors.divider, height: 1),
                ),
                PlanFeaturesWidget(plan: plan),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper.withValues(alpha: 0.6),
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.wine.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: QeranColors.inkMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.subscriptions_free_plan_title.t(context),
                      style: QeranTypography.subtitle.copyWith(
                        color: QeranColors.wine,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.subscriptions_price_free.t(context),
                      style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: QeranColors.inkMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  LocaleKeys.subscriptions_badge_you_are_here.t(context),
                  style: QeranTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: QeranColors.inkBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
