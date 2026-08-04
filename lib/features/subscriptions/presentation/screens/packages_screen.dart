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

import '../blocs/plans/subscription_plans_cubit.dart';
import '../blocs/plans/subscription_plans_state.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/current/current_subscription_state.dart';
import '../widgets/order_summary_widget.dart';
import '../widgets/paywall_hero_widget.dart';
import '../widgets/paywall_purchase_flow.dart';
import '../widgets/plan_selection_widget.dart';
import '../widgets/restore_purchases_tile.dart';
import '../widgets/sticky_cta_widget.dart';

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
      return const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _VipCelebratingWidget(),
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
                storeProduct:
                    state.storeProductFor(selectedPricing, isIOS: _isIOS),
                // Android keeps sending the Google id it has always sent; iOS
                // resolves its own, though the field is hidden there anyway.
                codeProductId: _isIOS
                    ? (selectedPricing.appleProductId ??
                        selectedPricing.storeProductId)
                    : selectedPricing.googleProductId,
                allowDiscountCode: !_isIOS,
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
                  hasSelection: selectedPricing != null,
                  freeBusy: freeBusy,
                  discountPercent: discountPercent,
                  onPressed: selectedPricing == null
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

class _VipCelebratingWidget extends StatelessWidget {
  const _VipCelebratingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.eHero,
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.cardR,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [QeranColors.wineLight, QeranColors.wine],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: QeranColors.gold.withValues(alpha: 0.18),
                      border: Border.all(color: QeranColors.gold, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: QeranColors.gold,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    LocaleKeys.subscriptions_vip_celebrate_subtitle.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.headline.copyWith(
                      color: QeranColors.paper,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleKeys.subscriptions_vip_celebrate_body.t(context),
                    textAlign: TextAlign.center,
                    style: QeranTypography.bodySm.copyWith(
                      color: QeranColors.gold.withValues(alpha: 0.80),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: QeranColors.gold,
                        ),
                      ),
                      QeranSpacing.hs8,
                      Text(
                        LocaleKeys.subscriptions_vip_active_features.t(context),
                        style: QeranTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: QeranColors.wine,
                        ),
                      ),
                    ],
                  ),
                  QeranSpacing.vs12,
                  _CelebratingFeatureRow(
                    label: LocaleKeys.subscriptions_feature_likes_label.t(context),
                  ),
                  _CelebratingFeatureRow(
                    label: LocaleKeys.subscriptions_feature_serious_interests_label.t(context),
                  ),
                  _CelebratingFeatureRow(
                    label: LocaleKeys.subscriptions_feature_photo_exchanges_label.t(context),
                  ),
                  _CelebratingFeatureRow(
                    label: LocaleKeys.subscriptions_feature_daily_profile_views_label.t(context),
                  ),
                  const SizedBox(height: 28),
                  QeranButton(
                    label: LocaleKeys.subscriptions_vip_back_to_profile.t(context),
                    onPressed: () => Navigator.of(context).pop(),
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

class _CelebratingFeatureRow extends StatelessWidget {
  final String label;
  const _CelebratingFeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
                size: 17,
                color: QeranColors.goldDeep,
              ),
              QeranSpacing.hs4,
              Text(
                LocaleKeys.subscriptions_unlimited.t(context),
                style: QeranTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: QeranColors.goldDeep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
