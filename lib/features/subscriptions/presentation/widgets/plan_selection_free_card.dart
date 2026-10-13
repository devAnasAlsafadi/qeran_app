part of 'plan_selection_widget.dart';

/// The free-tier card at the top of the packages list. Renders the same
/// backend-driven feature list as the paid cards ([PlanFeaturesWidget]:
/// `featuresAr`/`featuresEn` bullets, falling back to the numeric quota
/// checklist — likes / photo-exchanges / … — from `features{}`), plus two
/// free-specific states:
/// * [isActive] true  → the user already has an ACTIVE free subscription:
///   shows the "أنت هنا الآن" badge (no CTA).
/// * [isActive] false → no subscription yet: shows an **Activate** CTA that
///   fires user-initiated free activation (never auto-activated).
/// Private to the [PlanSelectionWidget] library.
class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard({
    required this.plan,
    required this.isActive,
    required this.busy,
    required this.onActivate,
  });

  /// The backend free plan. The card isn't drawn without one (H2).
  final SubscriptionPlan plan;
  final bool isActive;
  final bool busy;
  final VoidCallback? onActivate;

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
              Icon(
                isActive ? Icons.check_circle_rounded : Icons.redeem_rounded,
                color: isActive ? QeranColors.inkMuted : QeranColors.goldDeep,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: _FreeCardTitle(plan: plan)),
              if (isActive) const _YouAreHereBadge(),
            ],
          ),
          // Feature list — same backend-driven component (and layout) as the
          // paid cards: bullets when the backend supplies them, otherwise the
          // numeric quota checklist.
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: QeranColors.divider, height: 1),
          ),
          PlanFeaturesWidget(plan: plan),
          if (!isActive) ...[
            const SizedBox(height: 14),
            QeranButton(
              label: LocaleKeys.subscriptions_free_activate_cta.t(context),
              variant: QeranButtonVariant.primaryGold,
              size: QeranButtonSize.md,
              loading: busy,
              onPressed: onActivate,
            ),
          ],
        ],
      ),
    );
  }
}

/// The free plan's name, its tagline and its period, all the API's (run 10):
/// «الباقة المجانية», «جرّب قِران شهراً مجاناً», «شهر مجاني». Our own title
/// stands in only when the API sends no name.
class _FreeCardTitle extends StatelessWidget {
  const _FreeCardTitle({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final name = plan.name(isArabic: isArabic);
    final pricing = plan.activePricings.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isNotEmpty
              ? name
              : LocaleKeys.subscriptions_free_plan_title.t(context),
          style: QeranTypography.subtitle.copyWith(
            color: QeranColors.wine,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (plan.subtitle(isArabic: isArabic) case final subtitle?) ...[
          const SizedBox(height: 2),
          _PlanSubtitle(subtitle),
        ],
        if (pricing != null) ...[
          const SizedBox(height: 2),
          Text(
            pricePeriod(context, pricing, null),
            style: QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
          ),
        ],
      ],
    );
  }
}

/// The gold-neutral "أنت هنا الآن" pill — only shown for an active free sub.
class _YouAreHereBadge extends StatelessWidget {
  const _YouAreHereBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: QeranColors.inkMuted.withValues(alpha: 0.12),
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        LocaleKeys.subscriptions_badge_you_are_here.t(context),
        style: QeranTypography.bodySm.copyWith(
          fontSize: 11,
          color: QeranColors.inkBody,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
