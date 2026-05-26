import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import '../../domain/usecases/validate_discount_code_usecase.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/purchase/subscription_purchase_cubit.dart';
import '../blocs/purchase/subscription_purchase_state.dart';
import '../widgets/discount_code_field.dart';
import '../widgets/plan_visual.dart';

/// Arguments threaded into [RouteNames.subscriptionPurchase].
class SubscriptionPurchaseArgs {
  final SubscriptionPlan plan;
  final SubscriptionPricing pricing;

  const SubscriptionPurchaseArgs({
    required this.plan,
    required this.pricing,
  });
}

/// Purchase screen. Constructs its own screen-scoped
/// [SubscriptionPurchaseCubit] directly — no GetIt `factoryParam`
/// indirection. The cubit's dependencies are pulled from `sl<>()`;
/// the `pricing` comes from the route arguments. No `initState` /
/// `dispose` lifecycle hooks: the payment gateway now uses the
/// app-wide navigator key from DI, so the screen has no static state
/// to wire up.
class SubscriptionPurchaseScreen extends StatelessWidget {
  final SubscriptionPurchaseArgs args;
  const SubscriptionPurchaseScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubscriptionPurchaseCubit>(
      create: (_) => SubscriptionPurchaseCubit(
        pricing: args.pricing,
        validateDiscount: sl<ValidateDiscountCodeUseCase>(),
        subscribe: sl<SubscribeUseCase>(),
        paymentGateway: sl<PaymentGateway>(),
      ),
      child: _PurchaseView(args: args),
    );
  }
}

class _PurchaseView extends StatelessWidget {
  final SubscriptionPurchaseArgs args;
  const _PurchaseView({required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionPurchaseCubit, SubscriptionPurchaseState>(
      listener: _onStateChanged,
      builder: (context, state) {
        // BlocConsumer already drives rebuilds on state change — use
        // `read` (not `watch`) to grab the cubit instance, otherwise
        // we double-subscribe.
        final cubit = context.read<SubscriptionPurchaseCubit>();
        final inflight = state is SubscriptionPurchaseAwaitingPayment ||
            state is SubscriptionPurchaseSubscribing;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.transparent,
            elevation: 0,
            title: Text(
              LocaleKeys.subscriptions_purchase_title.t(context),
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: AbsorbPointer(
            absorbing: inflight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(
                    plan: args.plan,
                    pricing: args.pricing,
                    effectivePrice: cubit.effectivePrice,
                  ),
                  const SizedBox(height: AppDimens.p16),
                  const DiscountCodeField(),
                  const SizedBox(height: AppDimens.p24),
                  CustomButton(
                    text: LocaleKeys.subscriptions_confirm_cta.t(context),
                    backgroundColor: AppColors.primary,
                    isLoading: inflight,
                    onPressed: state is SubscriptionPurchaseSuccess
                        ? null
                        : cubit.confirmPurchase,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, SubscriptionPurchaseState state) {
    if (state is SubscriptionPurchaseSuccess) {
      // Push the new subscription into the app-scoped cubit so the
      // Profile screen / paywall react immediately without an extra
      // /current round-trip.
      context
          .read<CurrentSubscriptionCubit>()
          .onSubscribed(state.subscription);
      AppSnackBar.show(
        context,
        message: LocaleKeys.subscriptions_subscribe_success.t(context),
        type: SnackBarType.success,
      );
      // Drop both purchase + packages routes so the user lands on the
      // previous screen (Profile / wherever).
      NavigationManager.pop(context);
      if (Navigator.canPop(context)) {
        NavigationManager.pop(context);
      }
    } else if (state is SubscriptionPurchaseFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final SubscriptionPricing pricing;
  final double effectivePrice;

  const _SummaryCard({
    required this.plan,
    required this.pricing,
    required this.effectivePrice,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PlanVisual.parseColor(plan.color);
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final priceChanged = effectivePrice < pricing.price;
    final durationLabel = pricing.labelAr ??
        pricing.labelEn ??
        LocaleKeys.subscriptions_duration_days
            .t(context)
            .replaceFirst('{days}', '${pricing.durationDays}');

    return Container(
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14431C33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  plan.icon.isEmpty ? '💎' : plan.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nameAr,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      durationLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.p16),
          Container(
            height: 1,
            color: accent.withValues(alpha: 0.10),
          ),
          const SizedBox(height: AppDimens.p16),
          Text(
            LocaleKeys.subscriptions_final_price.t(context),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${effectivePrice.toStringAsFixed(2)} $currency',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                ),
              ),
              if (priceChanged) ...[
                const SizedBox(width: AppDimens.p8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${pricing.price.toStringAsFixed(2)} $currency',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
