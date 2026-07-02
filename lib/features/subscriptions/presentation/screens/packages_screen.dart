import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/plans/subscription_plans_cubit.dart';
import '../blocs/plans/subscription_plans_state.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';
import '../widgets/discount_code_widget.dart';
import '../widgets/paywall_hero_widget.dart';
import '../widgets/paywall_purchase_flow.dart';
import '../widgets/plan_selection_widget.dart';
import '../widgets/sticky_cta_widget.dart';

/// Full-route packages screen — thin coordinator. Provides the plans + purchase
/// cubits, composes the extracted paywall widgets, and delegates CTA routing to
/// [PaywallPurchaseFlow] (free → `/subscribe`; paid → RevenueCat, iOS locked
/// per Q-B; same product → route to اشتراكي).
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
    if (state.plans.isEmpty) {
      return QeranEmptyState(
        title: LocaleKeys.subscriptions_empty_plans.t(context),
        icon: Icons.workspace_premium_outlined,
      );
    }
    final activeIndex = _activePlanIndex.clamp(0, state.plans.length - 1);
    final activePlan = state.plans[activeIndex];
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
            const PaywallHeroWidget(),
            QeranSpacing.vs20,
            PlanSelectionWidget(
              plans: state.plans,
              activeIndex: activeIndex,
              activePlan: activePlan,
              selectedPricingId: selectedPricing?.id,
              onPlanChanged: _setActivePlan,
              onPricingSelected: (pricingId) => cubit.selectPricing(
                planId: activePlan.id,
                pricingId: pricingId,
              ),
            ),
            if (!_isIOS && selectedPricing != null) ...[
              QeranSpacing.vs16,
              DiscountCodeWidget(pricing: selectedPricing),
            ],
            QeranSpacing.vs24,
            BlocBuilder<PackagePurchaseCubit, PackagePurchaseState>(
              builder: (context, purchaseState) {
                final discountPercent =
                    purchaseState is PackagePurchaseCodeValidationSuccess
                        ? purchaseState.response.discountPercent
                        : null;
                return StickyCtaWidget(
                  isIOS: _isIOS,
                  hasSelection: selectedPricing != null,
                  freeBusy: freeBusy,
                  discountPercent: discountPercent,
                  onPressed: selectedPricing == null
                      ? null
                      : () => handleCta(context, activePlan, selectedPricing),
                );
              },
            ),
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
