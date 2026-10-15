part of 'plan_selection_widget.dart';

/// One selectable plan card in the packages list. Renders the plan header
/// (name + popular tag + selected/owned badge), the header price bound to the
/// selected pricing, the billing-period picker (a selected plan with more
/// than one period, their own included: run 11), and the expanded features
/// list. Private to the [PlanSelectionWidget] library.
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final int index;
  final bool isSelected;
  final int? ownedPlanId;

  /// A plan above the one they hold: «ترقية متاحة».
  final bool isUpgrade;

  /// Resolved period of the plan the user actually owns (e.g. "3 أشهر" /
  /// "3 months"), or null when nothing is owned. Rendered on the owned card's
  /// "your plan" badge so a VIP-3-month subscriber sees their real pricing.
  final String? ownedPeriodLabel;
  final bool isArabic;
  final SubscriptionPricing? Function(SubscriptionPlan plan) selectedPricingFor;
  final StoreProduct? Function(SubscriptionPricing pricing) resolveStoreProduct;

  /// False while the store catalogue is still loading — see [PlanSelectionWidget].
  final bool storeResolved;
  final ValueChanged<int> onPlanChanged;
  final ValueChanged<int> onPricingSelected;

  const _PlanCard({
    required this.plan,
    required this.index,
    required this.isSelected,
    required this.ownedPlanId,
    required this.isUpgrade,
    required this.ownedPeriodLabel,
    required this.isArabic,
    required this.selectedPricingFor,
    required this.resolveStoreProduct,
    required this.storeResolved,
    required this.onPlanChanged,
    required this.onPricingSelected,
  });

  /// Plan-card price summary: the localized store price with the period it pays
  /// for ("SAR 99.99 / 3 أشهر"), never a fixed «/شهر».
  ///
  /// Returns null when there is no store price to show — the caller then draws
  /// a placeholder, or nothing. The API's `price` is never shown: it is an
  /// administrative figure with no currency, not what the store charges.
  String? _priceLabel(
    BuildContext context,
    SubscriptionPricing? pricing,
    StoreProduct? storeProduct,
  ) {
    if (pricing == null || storeProduct == null) return null;
    return priceWithPeriod(context, storeProduct, pricing);
  }

  @override
  Widget build(BuildContext context) {
    final isOwned = plan.id == ownedPlanId;

    // The badge: the dashboard's own text once it sends one (TQ20), until
    // then ours on the plan it marks isPopular — never by tier (run 10).
    final badge = plan.hasBadgeFields
        ? plan.badge(isArabic: isArabic)
        : (plan.isPopular
            ? LocaleKeys.subscriptions_badge_popular.t(context)
            : null);

    // Plan-card price: bound to the SELECTED pricing (the same one the summary,
    // CTA and charge read) — falling back to the first active pricing before a
    // selection exists: the store price, a placeholder until the store
    // answers, or nothing when it has none.
    final activePricings = plan.activePricings;
    final selectedPricing = selectedPricingFor(plan) ??
        (activePricings.isNotEmpty ? activePricings.first : null);
    final storeProduct =
        selectedPricing != null ? resolveStoreProduct(selectedPricing) : null;
    final priceText = _priceLabel(context, selectedPricing, storeProduct);

    return GestureDetector(
      onTap: () => onPlanChanged(index),
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
                  _PlanMark(owned: isOwned, selected: isSelected),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A Wrap, so a long name or a large font puts the
                        // badge under the name instead of overflowing.
                        Wrap(
                          spacing: QeranSpacing.s8,
                          runSpacing: QeranSpacing.s4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              plan.name(isArabic: isArabic),
                              style: QeranTypography.subtitle.copyWith(
                                color: QeranColors.wine,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (badge != null) ...[
                              _PillBadge(
                                label: badge,
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
                        if (plan.subtitle(isArabic: isArabic)
                            case final subtitle?) ...[
                          const SizedBox(height: 2),
                          _PlanSubtitle(subtitle),
                        ],
                        const SizedBox(height: 2),
                        _PlanCardPrice(
                          priceText: priceText,
                          storeResolved: storeResolved,
                        ),
                      ],
                    ),
                  ),
                  _PlanStatus(
                    owned: isOwned,
                    upgrade: isUpgrade,
                    ownedPeriodLabel: ownedPeriodLabel,
                  ),
                ],
              ),

              // Billing-period picker — sits directly under the header price,
              // above the features. Only for the selected plan when it exposes
              // more than one pricing, their own plan included (the period
              // they don't hold); a single-pricing plan (e.g. Basic) shows
              // nothing.
              if (isSelected && activePricings.length > 1) ...[
                QeranSpacing.vs12,
                PlanPricingSelector(
                  plan: plan,
                  selectedPricingId: selectedPricing?.id,
                  resolveStoreProduct: resolveStoreProduct,
                  storeResolved: storeResolved,
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
