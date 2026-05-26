import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
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
import '../blocs/plans/subscription_plans_cubit.dart';
import '../blocs/plans/subscription_plans_state.dart';
import '../screens/subscription_purchase_screen.dart';
import '../widgets/plan_card.dart';

/// Full-route packages screen. Lists dashboard-defined plans (no
/// hardcoded prices or IDs), lets the user pick one pricing per plan,
/// and pushes the purchase screen with the selected pricing.
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

class _PackagesView extends StatelessWidget {
  const _PackagesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      appBar: QeranAppBar(title: LocaleKeys.subscriptions_title.t(context)),
      body: BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionPlansInitial() ||
            SubscriptionPlansLoading() =>
              const Center(child: QeranLoader()),
            SubscriptionPlansFailure(:final message) =>
              _ErrorState(message: message.t(context)),
            SubscriptionPlansLoaded() => _PlansList(state: state),
          };
        },
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

class _PlansList extends StatelessWidget {
  final SubscriptionPlansLoaded state;
  const _PlansList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.plans.isEmpty) {
      return QeranEmptyState(
        title: LocaleKeys.subscriptions_empty_plans.t(context),
        icon: Icons.workspace_premium_outlined,
      );
    }
    final cubit = context.read<SubscriptionPlansCubit>();
    // Header is rendered as the first item in the ListView. Two
    // chunks: the wine-deep premium banner, then a soft supportive
    // line — same emotional triad as paywall (hero → context → cards).
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s16,
        QeranSpacing.s20,
        QeranSpacing.s32,
      ),
      itemCount: state.plans.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: QeranSpacing.s16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _PackagesHeader();
        }
        final plan = state.plans[index - 1];
        final pricing = cubit.pricingFor(plan);
        return PlanCard(
          plan: plan,
          selectedPricing: pricing,
          onSelectPricing: (pricingId) => cubit.selectPricing(
            planId: plan.id,
            pricingId: pricingId,
          ),
          onSubscribe: pricing == null
              ? null
              : () => _openPurchase(context, plan: plan, pricing: pricing),
        );
      },
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

class _PackagesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QeranSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QeranPremiumBanner(
            title: LocaleKeys.subscriptions_status_not_subscribed_title
                .t(context),
            subtitle: LocaleKeys.subscriptions_status_not_subscribed_body
                .t(context),
          ),
          QeranSpacing.vs20,
          Text(
            LocaleKeys.subscriptions_subtitle.t(context),
            style: QeranTypography.body,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
