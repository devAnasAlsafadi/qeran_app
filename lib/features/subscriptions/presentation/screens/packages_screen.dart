import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_gate_banner.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_features.dart';
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

part 'packages_vip_celebration.dart';

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
  int _activePlanIndex = 0;
  final bool _isIOS = Platform.isIOS;

  void _setActivePlan(int index) {
    if (index == _activePlanIndex) return;
    setState(() => _activePlanIndex = index);
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
    // Selectable list = purchasable plans only. The free tier is rendered as the
    // static "you are here" card inside PlanSelectionWidget, so it's excluded
    // here to avoid a double render. Guarding on `paidPlans` (⊇ `plans.isEmpty`)
    // also protects the index math below from a free-only payload.
    final paidPlans = state.paidPlans;
    if (paidPlans.isEmpty) {
      return QeranEmptyState(
        title: LocaleKeys.subscriptions_empty_plans.t(context),
        icon: Icons.workspace_premium_outlined,
      );
    }

    final currentSubState = context.watch<CurrentSubscriptionCubit>().state;
    final currentSub = currentSubState is CurrentSubscriptionLoaded &&
            currentSubState.subscription.isCurrentlyActive
        ? currentSubState.subscription
        : null;

    final isVipOwned = currentSub != null && currentSub.plan.isVipTier;
    final isBasicOwned = currentSub != null && currentSub.plan.isBasicTier;

    if (isVipOwned) {
      return SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _VipCelebratingWidget(features: currentSub.plan.features),
        ),
      );
    }

    int activeIndex = _activePlanIndex.clamp(0, paidPlans.length - 1);
    if (isBasicOwned) {
      final vipIndex = paidPlans.indexWhere((p) => p.isVipTier);
      if (vipIndex != -1) {
        activeIndex = vipIndex;
      }
    }

    final activePlan = paidPlans[activeIndex];
    final cubit = context.read<SubscriptionPlansCubit>();
    final selectedPricing = cubit.pricingFor(activePlan);
    // No store price means no purchase: the amount cannot be disclosed, and
    // RevenueCat would fail to find the package anyway. Once the store has
    // answered without it, the code field and the button give way to one
    // line saying so (runs 10 and 11).
    final selectedStore = selectedPricing == null
        ? null
        : state.storeProductFor(selectedPricing, isIOS: _isIOS);
    final priceUnavailable = selectedPricing != null && selectedStore == null;
    final unavailable = priceUnavailable && state.storeResolved;

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
              selectedPricingFor: cubit.pricingFor,
              onPlanChanged: _setActivePlan,
              onPricingSelected: (pricingId) => cubit.selectPricing(
                planId: activePlan.id,
                pricingId: pricingId,
              ),
              resolveStoreProduct: (pricing) =>
                  state.storeProductFor(pricing, isIOS: _isIOS),
              storeResolved: state.storeResolved,
              currentSub: currentSub,
              freePlan: state.freePlan,
              freeBusy: freeBusy,
              onActivateFree: () => activateFree(context),
            ),
            if (selectedPricing != null) ...[
              QeranSpacing.vs16,
              OrderSummaryWidget(
                planName: activePlan.name(
                  isArabic:
                      Localizations.localeOf(context).languageCode == 'ar',
                ),
                pricing: selectedPricing,
                storeProduct: selectedStore,
                // Android keeps sending the Google id it has always sent; iOS
                // resolves its own, though the field is hidden there anyway.
                codeProductId: _isIOS
                    ? (selectedPricing.appleProductId ??
                        selectedPricing.storeProductId)
                    : selectedPricing.googleProductId,
                allowDiscountCode: !_isIOS && !unavailable,
              ),
            ],
            QeranSpacing.vs24,
            BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
              builder: (context, purchaseState) {
                final discountPercent =
                    purchaseState is PackagePurchaseCodeValidationSuccess
                        ? purchaseState.response.discountPercent
                        : null;
                return StickyCtaWidget(
                  unavailable: unavailable,
                  hasSelection: selectedPricing != null && !priceUnavailable,
                  freeBusy: freeBusy,
                  discountPercent: discountPercent,
                  onPressed: selectedPricing == null || priceUnavailable
                      ? null
                      : () => handleCta(context, activePlan, selectedPricing),
                );
              },
            ),
            QeranSpacing.vs12,
            // Apple requires a visible "Restore purchases" on the purchase
            // surface. Self-contained tile (own cubit + restore-specific outcome
            // handling), enabled on both platforms — restore triggers no payment.
            const RestorePurchasesTile(),
            QeranSpacing.vs12,
            // Apple 3.1.2(a): the subscription binding + both legal documents
            // must be reachable from the surface that sells the subscription.
            const LegalLinksRow(),
          ],
        ),
      ),
    );
  }
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
