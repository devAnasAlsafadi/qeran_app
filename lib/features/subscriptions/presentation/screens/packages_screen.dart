import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        title: Text(
          LocaleKeys.subscriptions_title.t(context),
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocBuilder<SubscriptionPlansCubit, SubscriptionPlansState>(
        builder: (context, state) {
          return switch (state) {
            SubscriptionPlansInitial() ||
            SubscriptionPlansLoading() =>
              const _LoadingState(),
            SubscriptionPlansFailure(:final message) =>
              _ErrorState(message: message.t(context)),
            SubscriptionPlansLoaded() => _PlansList(state: state),
          };
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimens.p12),
          Text(
            LocaleKeys.subscriptions_load_failed.t(context),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.p16),
          TextButton(
            onPressed: () =>
                context.read<SubscriptionPlansCubit>().load(),
            child: Text(
              LocaleKeys.subscriptions_retry.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansList extends StatelessWidget {
  final SubscriptionPlansLoaded state;
  const _PlansList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.plans.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.subscriptions_empty_plans.t(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    final cubit = context.read<SubscriptionPlansCubit>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p20,
        AppDimens.p12,
        AppDimens.p20,
        AppDimens.p32,
      ),
      itemCount: state.plans.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.p16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.p8),
            child: Text(
              LocaleKeys.subscriptions_subtitle.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
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
