import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_gate_banner.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/helpers/plan_offer.dart';
import '../blocs/plans/subscription_plans_cubit.dart';
import '../blocs/plans/subscription_plans_state.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/current/current_subscription_state.dart';
import '../widgets/legal_links_row.dart';
import '../widgets/order_summary_widget.dart';
import '../widgets/paywall_hero_widget.dart';
import '../widgets/paywall_purchase_flow.dart';
import '../widgets/plan_selection_widget.dart';
import '../widgets/restore_purchases_tile.dart';
import '../widgets/sticky_cta_widget.dart';
import '../widgets/subscription_activating_card.dart';

part 'packages_screen_parts.dart';

/// Full-route packages screen — thin coordinator. Provides the plans + purchase
/// cubits, composes the extracted paywall widgets, and delegates CTA routing to
/// [PaywallPurchaseFlow] (free → `/subscribe`; paid → RevenueCat; same product
/// → route to اشتراكي).
class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SubscriptionPlansCubit>(
          create: (_) => sl<SubscriptionPlansCubit>()..load(),
        ),
        BlocProvider<PackagePurchaseCubit>(
          create: (_) => sl<PackagePurchaseCubit>(),
        ),
      ],
      child: const _PackagesView(),
    );
  }
}

class _PackagesView extends StatefulWidget {
  const _PackagesView();

  @override
  State<_PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<_PackagesView>
    with PaywallPurchaseFlow<_PackagesView> {
  /// Null until they tap a plan: then [PlanOffer.initialIndex] decides.
  int? _activePlanIndex;

  /// Plans whose period they picked themselves: their own period stays
  /// picked; otherwise it is never preselected.
  final _pickedPeriod = <int>{};
  final bool _isIOS = Platform.isIOS;

  void _setActivePlan(int index) {
    if (index == _activePlanIndex) return;
    setState(() => _activePlanIndex = index);
  }

  void _pickPeriod(SubscriptionPlan plan, int pricingId) {
    setState(() => _pickedPeriod.add(plan.id));
    context.read<SubscriptionPlansCubit>().selectPricing(
          planId: plan.id,
          pricingId: pricingId,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QeranAppBar(title: LocaleKeys.subscriptions_title.t(context)),
      body: BlocListener<PackagePurchaseCubit, PackagePurchaseState>(
        listener: handlePurchaseState,
        child: BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
          builder: (context, state) => switch (state) {
            SubscriptionPlansInitial() ||
            SubscriptionPlansLoading() =>
              const Center(child: QeranLoader()),
            SubscriptionPlansFailure(:final message) =>
              _ErrorState(message: message.t(context)),
            SubscriptionPlansLoaded() => _buildLoaded(context, state),
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, SubscriptionPlansLoaded state) {
    final currentSubState = context.watch<CurrentSubscriptionCubit>().state;
    final currentSub = currentSubState is CurrentSubscriptionLoaded &&
            currentSubState.subscription.isCurrentlyActive
        ? currentSubState.subscription
        : null;
    // Selectable list = purchasable plans only, none below theirs (run 11: the
    // top plan lists itself too, for the period they don't hold — no more
    // celebration dead end). The free tier is the static card inside
    // PlanSelectionWidget. An empty list also guards the index math below.
    final offer = PlanOffer(state.paidPlans, owned: currentSub);
    final paidPlans = offer.plans;
    if (paidPlans.isEmpty) {
      return QeranEmptyState(
        title: LocaleKeys.subscriptions_empty_plans.t(context),
        icon: Icons.workspace_premium_outlined,
      );
    }

    final activeIndex = (_activePlanIndex ?? offer.initialIndex)
        .clamp(0, paidPlans.length - 1);
    final activePlan = paidPlans[activeIndex];
    final cubit = context.read<SubscriptionPlansCubit>();
    SubscriptionPricing? pricingFor(SubscriptionPlan plan) => offer.preselect(
          plan,
          cubit.pricingFor(plan),
          picked: _pickedPeriod.contains(plan.id),
        );
    final selectedPricing = pricingFor(activePlan);
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
            // Paid, not yet confirmed: said first, so nobody buys again.
            if (currentSubState
                case CurrentSubscriptionActivating(:final overdue)) ...[
              SubscriptionActivatingCard(overdue: overdue),
              QeranSpacing.vs16,
            ],
            const ProfileGateBanner(),
            const PaywallHeroWidget(),
            QeranSpacing.vs20,
            PlanSelectionWidget(
              plans: paidPlans,
              activeIndex: activeIndex,
              activePlan: activePlan,
              selectedPricingFor: pricingFor,
              onPlanChanged: _setActivePlan,
              onPricingSelected: (id) => _pickPeriod(activePlan, id),
              resolveStoreProduct: (pricing) =>
                  state.storeProductFor(pricing, isIOS: _isIOS),
              storeResolved: state.storeResolved,
              currentSub: currentSub,
              isUpgrade: offer.isUpgrade,
              freePlan: state.freePlan,
              freeBusy: freeBusy,
              onActivateFree: () => activateFree(context),
            ),
            _Checkout(
              plan: activePlan,
              pricing: selectedPricing,
              storeProduct: selectedPricing == null
                  ? null
                  : state.storeProductFor(selectedPricing, isIOS: _isIOS),
              storeResolved: state.storeResolved,
              owned: offer.isOwnedPricing(selectedPricing),
              isIOS: _isIOS,
              freeBusy: freeBusy,
              onBuy: () => handleCta(context, activePlan, selectedPricing!),
            ),
          ],
        ),
      ),
    );
  }
}
