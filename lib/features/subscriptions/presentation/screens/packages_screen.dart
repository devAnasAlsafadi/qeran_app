import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/design_system/widgets/qeran_premium_banner.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/subscription_format.dart';
import '../blocs/plans/subscription_plans_cubit.dart';
import '../blocs/plans/subscription_plans_state.dart';
import '../screens/subscription_purchase_screen.dart';

/// Full-route packages screen.
///
/// Restructured into a single-plan-at-a-time view with a segmented
/// control at the top to switch between plans (e.g. العادي / VIP):
///
/// * **Hero** — `QeranPremiumBanner` (wine-deep + ring motif).
/// * **Plan tabs** — paper card with animated gold underline. Hidden
///   when there's only one plan.
/// * **Section title** — "اختر باقتك".
/// * **Feature list** — gold check icons + wine labels derived from
///   `plan.features` so counts stay backend-driven (no hardcoded
///   numbers).
/// * **Pricing rows** — one row per pricing in the active plan. The
///   currently-selected row gets a gold border + cream-surface fill;
///   the trailing radio is gold-filled. Discounted rows get a small
///   gold "خصم ٢٠٪" chip.
/// * **Sticky CTA** — `QeranButton.primary` "اشترك الآن" that routes
///   to the existing `subscriptionPurchase` route with the active
///   plan + currently-selected pricing.
///
/// Business logic preserved verbatim from the previous list-of-cards
/// layout — same cubit calls (`selectPricing`, `pricingFor`), same
/// navigation arguments (`SubscriptionPurchaseArgs`).
class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionPlansCubit>(
      create: (_) => sl<SubscriptionPlansCubit>()..load(),
      child: const _PackagesView(),
    );
  }
}

class _PackagesView extends StatefulWidget {
  const _PackagesView();

  @override
  State<_PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<_PackagesView> {
  int _activePlanIndex = 0;

  void _setActivePlan(int index) {
    if (index == _activePlanIndex) return;
    setState(() => _activePlanIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QeranAppBar(title: LocaleKeys.subscriptions_title.t(context)),
      body: BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionPlansInitial() ||
            SubscriptionPlansLoading() =>
              const Center(child: QeranLoader()),
            SubscriptionPlansFailure(:final message) =>
              _ErrorState(message: message.t(context)),
            SubscriptionPlansLoaded() => _LoadedBody(
                state: state,
                activePlanIndex:
                    _activePlanIndex.clamp(0, _maxIndex(state.plans)),
                onActivePlanChanged: _setActivePlan,
              ),
          };
        },
      ),
    );
  }

  /// Defensive clamp so a stale `_activePlanIndex` can never index past
  /// a freshly-reloaded plans list. Returns 0 when the list is empty
  /// so the clamp is a no-op.
  static int _maxIndex(List<SubscriptionPlan> plans) =>
      plans.isEmpty ? 0 : plans.length - 1;
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return QeranErrorState(
      title: LocaleKeys.subscriptions_load_failed.t(context),
      message: message,
      retryLabel: LocaleKeys.subscriptions_retry.t(context),
      onRetry: () => context.read<SubscriptionPlansCubit>().load(),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final SubscriptionPlansLoaded state;
  final int activePlanIndex;
  final ValueChanged<int> onActivePlanChanged;

  const _LoadedBody({
    required this.state,
    required this.activePlanIndex,
    required this.onActivePlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (state.plans.isEmpty) {
      return QeranEmptyState(
        title: LocaleKeys.subscriptions_empty_plans.t(context),
        icon: Icons.workspace_premium_outlined,
      );
    }
    final activePlan = state.plans[activePlanIndex];
    final cubit = context.read<SubscriptionPlansCubit>();
    final selectedPricing = cubit.pricingFor(activePlan);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s20,
          QeranSpacing.s16,
          QeranSpacing.s20,
          QeranSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QeranPremiumBanner(
              title: LocaleKeys.subscriptions_status_not_subscribed_title
                  .t(context),
              subtitle: LocaleKeys.subscriptions_status_not_subscribed_body
                  .t(context),
            ),
            if (state.plans.length > 1) ...[
              QeranSpacing.vs20,
              _PlanTabs(
                plans: state.plans,
                activeIndex: activePlanIndex,
                onChanged: onActivePlanChanged,
              ),
            ],
            QeranSpacing.vs24,
            // Section title. Hardcoded — locale keys for the new
            // packages strings are deferred per the implementation
            // roadmap.
            Text(
              'اختر باقتك',
              style: QeranTypography.title.copyWith(color: QeranColors.wine),
            ),
            QeranSpacing.vs12,
            _PlanFeatureList(plan: activePlan),
            QeranSpacing.vs20,
            _PricingRows(
              plan: activePlan,
              selectedPricingId: selectedPricing?.id,
              onSelectPricing: (pricingId) => cubit.selectPricing(
                planId: activePlan.id,
                pricingId: pricingId,
              ),
            ),
            QeranSpacing.vs24,
            QeranButton(
              label: LocaleKeys.subscriptions_subscribe_cta.t(context),
              variant: QeranButtonVariant.primary,
              onPressed: selectedPricing == null
                  ? null
                  : () => _openPurchase(
                        context,
                        plan: activePlan,
                        pricing: selectedPricing,
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPurchase(
    BuildContext context, {
    required SubscriptionPlan plan,
    required SubscriptionPricing pricing,
  }) {
    NavigationManager.navigateTo(
      context,
      RouteNames.subscriptionPurchase,
      arguments: SubscriptionPurchaseArgs(plan: plan, pricing: pricing),
    );
  }
}

/// Two-or-more-cell segmented control mirroring `LikesSegmentedTabs`
/// styling: paper card with a wine-tinted shadow, animated gold
/// underline that slides via `AnimatedPositionedDirectional` so it
/// lands correctly in RTL and LTR without per-locale branching.
class _PlanTabs extends StatelessWidget {
  final List<SubscriptionPlan> plans;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _PlanTabs({
    required this.plans,
    required this.activeIndex,
    required this.onChanged,
  });

  static const Duration _animDur = Duration(milliseconds: 280);
  static const double _barHeight = 3.0;
  static const double _barWidth = 40.0;
  static const double _cardRadius = 22.0;
  static const double _cardHeight = 56.0;
  static const double _innerPad = 4.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _cardHeight,
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: BorderRadius.circular(_cardRadius),
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
                  duration: _animDur,
                  curve: Curves.easeOutCubic,
                  start: barStart,
                  bottom: 6,
                  width: _barWidth,
                  height: _barHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: QeranColors.gold,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < plans.length; i++)
                      Expanded(
                        child: _PlanTabCell(
                          label: plans[i].nameAr,
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
          duration: _PlanTabs._animDur,
          curve: Curves.easeOutCubic,
          style: QeranTypography.subtitle.copyWith(
            color: isActive ? QeranColors.wine : QeranColors.inkMuted,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Feature checklist derived from `plan.features`. Numeric counts come
/// from the backend (likes / photo exchanges / serious interests /
/// daily profile views) — never hardcoded. Each row is a gold check +
/// wine label.
class _PlanFeatureList extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanFeatureList({required this.plan});

  @override
  Widget build(BuildContext context) {
    final f = plan.features;
    final items = <String>[
      SubscriptionFormat.formatAllowed(
        context,
        f.likesAllowed,
        LocaleKeys.subscriptions_feature_likes.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.seriousInterestsAllowed,
        LocaleKeys.subscriptions_feature_serious_interests.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.photoExchangesAllowed,
        LocaleKeys.subscriptions_feature_photo_exchanges.t(context),
      ),
      SubscriptionFormat.formatAllowed(
        context,
        f.dailyProfileViewsAllowed,
        LocaleKeys.subscriptions_feature_daily_profile_views.t(context),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in items) _FeatureCheckRow(label: label),
      ],
    );
  }
}

class _FeatureCheckRow extends StatelessWidget {
  final String label;
  const _FeatureCheckRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: QeranColors.gold,
          ),
          QeranSpacing.hs12,
          Expanded(
            child: Text(
              label,
              style: QeranTypography.body.copyWith(color: QeranColors.wine),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical stack of pricing options for the active plan. Each row is
/// tappable; selection drives the active state via the cubit so the
/// existing `pricingFor(plan)` continues to return the right pricing
/// for the CTA route.
class _PricingRows extends StatelessWidget {
  final SubscriptionPlan plan;
  final int? selectedPricingId;
  final ValueChanged<int> onSelectPricing;

  const _PricingRows({
    required this.plan,
    required this.selectedPricingId,
    required this.onSelectPricing,
  });

  @override
  Widget build(BuildContext context) {
    final pricings = plan.activePricings;
    if (pricings.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pricing in pricings)
          Padding(
            padding: const EdgeInsets.only(bottom: QeranSpacing.s12),
            child: _PricingRow(
              pricing: pricing,
              selected: pricing.id == selectedPricingId,
              onTap: () => onSelectPricing(pricing.id),
            ),
          ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final SubscriptionPricing pricing;
  final bool selected;
  final VoidCallback onTap;

  const _PricingRow({
    required this.pricing,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final label = pricing.labelAr ??
        pricing.labelEn ??
        LocaleKeys.subscriptions_duration_days
            .t(context)
            .replaceFirst('{days}', '${pricing.durationDays}');
    return Material(
      color: selected ? QeranColors.creamSurface : QeranColors.paper,
      borderRadius: QeranRadii.controlR,
      child: InkWell(
        onTap: onTap,
        borderRadius: QeranRadii.controlR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            borderRadius: QeranRadii.controlR,
            border: Border.all(
              color: selected ? QeranColors.gold : QeranColors.wine08,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              _RadioDot(selected: selected),
              QeranSpacing.hs12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: QeranTypography.subtitle.copyWith(
                        color: QeranColors.wine,
                      ),
                    ),
                    if (pricing.durationDays > 30) ...[
                      QeranSpacing.vs4,
                      Text(
                        '${pricing.monthlyEquivalent.toStringAsFixed(2)} '
                        '$currency${LocaleKeys.subscriptions_per_month.t(context)}',
                        style: QeranTypography.caption.copyWith(
                          color: QeranColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              QeranSpacing.hs12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                        '${pricing.price.toStringAsFixed(0)} $currency',
                        style: QeranTypography.numeric.copyWith(
                          fontSize: 18,
                          color: QeranColors.wine,
                        ),
                      ),
                    ],
                  ),
                  if (pricing.hasDiscountBadge) ...[
                    QeranSpacing.vs4,
                    QeranChip(
                      label: 'خصم ${pricing.discountPercent}٪',
                      variant: QeranChipVariant.interest,
                      compact: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom radio indicator — gold-filled when selected, wine-outlined
/// when not. Avoids the Material radio's grey/blue ripple so the
/// surface stays on-brand.
class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.gold : QeranColors.wine20,
          width: selected ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.gold,
              ),
            )
          : null,
    );
  }
}
