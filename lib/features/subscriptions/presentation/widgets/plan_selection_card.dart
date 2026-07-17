part of 'plan_selection_widget.dart';

/// One selectable plan card in the packages list. Renders the plan header
/// (name + popular tag + selected/owned badge), the header price bound to the
/// selected pricing, the billing-period picker (multi-pricing purchase
/// candidates only), and the expanded features list. Private to the
/// [PlanSelectionWidget] library.
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final int index;
  final bool isSelected;
  final int? ownedPlanId;

  /// Resolved period of the plan the user actually owns (e.g. "3 أشهر" /
  /// "3 months"), or null when nothing is owned. Rendered on the owned card's
  /// "your plan" badge so a VIP-3-month subscriber sees their real pricing.
  final String? ownedPeriodLabel;
  final bool isArabic;
  final SubscriptionPricing? Function(SubscriptionPlan plan) selectedPricingFor;
  final StoreProduct? Function(SubscriptionPricing pricing) resolveStoreProduct;
  final ValueChanged<int> onPlanChanged;
  final ValueChanged<int> onPricingSelected;

  const _PlanCard({
    required this.plan,
    required this.index,
    required this.isSelected,
    required this.ownedPlanId,
    required this.ownedPeriodLabel,
    required this.isArabic,
    required this.selectedPricingFor,
    required this.resolveStoreProduct,
    required this.onPlanChanged,
    required this.onPricingSelected,
  });

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

  @override
  Widget build(BuildContext context) {
    final isOwned = plan.id == ownedPlanId;

    // Check if it's the VIP plan to show popular tag
    final isVip = plan.isVipTier;

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
                              _PillBadge(
                                label: LocaleKeys.subscriptions_badge_popular
                                    .t(context),
                                background:
                                    QeranColors.gold.withValues(alpha: 0.18),
                                foreground: QeranColors.goldDeep,
                                fontSize: 10,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
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
                    _PillBadge(
                      label: ownedPlanBadgeLabel(
                        LocaleKeys.subscriptions_badge_your_plan.t(context),
                        ownedPeriodLabel,
                      ),
                      background: QeranColors.wine.withValues(alpha: 0.08),
                      foreground: QeranColors.wine,
                    ),
                  if (!isOwned && ownedPlanId != null)
                    _PillBadge(
                      label: LocaleKeys.subscriptions_badge_upgrade_available
                          .t(context),
                      background: QeranColors.gold.withValues(alpha: 0.18),
                      foreground: QeranColors.goldDeep,
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

/// Rounded status pill used for the plan-card badges (popular tag, "your plan",
/// "upgrade available"). One shape, parameterised on label + colours so the
/// three badges never drift apart.
class _PillBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const _PillBadge({
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        label,
        style: QeranTypography.bodySm.copyWith(
          fontSize: fontSize,
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
