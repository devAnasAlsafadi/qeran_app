import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_app_bar.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/services/payment_gateway.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import '../../domain/usecases/validate_discount_code_usecase.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/purchase/subscription_purchase_cubit.dart';
import '../blocs/purchase/subscription_purchase_state.dart';
import '../widgets/checkout_features_card.dart';
import '../widgets/checkout_payment_methods.dart';
import '../widgets/checkout_summary_card.dart';
import '../widgets/checkout_trust_signals.dart';
import '../widgets/discount_code_field.dart';

/// Arguments threaded into [RouteNames.subscriptionPurchase].
class SubscriptionPurchaseArgs {
  final SubscriptionPlan plan;
  final SubscriptionPricing pricing;

  const SubscriptionPurchaseArgs({
    required this.plan,
    required this.pricing,
  });
}

/// Conversion-optimised checkout. Cubit construction, state listener,
/// and the success/failure side-effects all match the previous screen
/// verbatim — only the visual structure changed.
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
        final cubit = context.read<SubscriptionPurchaseCubit>();
        final inflight = state is SubscriptionPurchaseAwaitingPayment ||
            state is SubscriptionPurchaseSubscribing;
        return Scaffold(
          backgroundColor: QeranColors.creamCanvas,
          appBar: QeranAppBar(
            title: LocaleKeys.subscriptions_purchase_title.t(context),
          ),
          body: AbsorbPointer(
            absorbing: inflight,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                QeranSpacing.s20,
                QeranSpacing.s12,
                QeranSpacing.s20,
                QeranSpacing.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CheckoutSummaryCard(
                    plan: args.plan,
                    pricing: args.pricing,
                    effectivePrice: cubit.effectivePrice,
                  ),
                  const SizedBox(height: QeranSpacing.s16),
                  CheckoutFeaturesCard(features: args.plan.features),
                  const SizedBox(height: QeranSpacing.s16),
                  const _PromoSection(),
                  const SizedBox(height: QeranSpacing.s20),
                  const CheckoutPaymentMethods(),
                  const SizedBox(height: QeranSpacing.s16),
                  const CheckoutTrustSignals(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _BottomCta(
            effectivePrice: cubit.effectivePrice,
            inflight: inflight,
            disabled: state is SubscriptionPurchaseSuccess,
            onTap: cubit.confirmPurchase,
          ),
        );
      },
    );
  }

  void _onStateChanged(BuildContext context, SubscriptionPurchaseState state) {
    if (state is SubscriptionPurchaseSuccess) {
      context
          .read<CurrentSubscriptionCubit>()
          .onSubscribed(state.subscription);
      // Pop FIRST, then surface the snackbar on the destination route.
      // Showing it on `context` before pop binds the OverlayEntry to
      // the checkout's Overlay — which gets disposed mid-animation,
      // orphaning the entry and freezing the user for 3 s on the
      // destination screen.
      NavigationManager.pop(context);
      if (Navigator.canPop(context)) {
        NavigationManager.pop(context);
      }
      // Defer to the next frame so the destination route is fully
      // mounted, then show the snackbar via the root navigator's
      // OverlayState (NOT navigatorKey.currentContext — that returns
      // the Navigator's own context which sits ABOVE the Overlay,
      // so Overlay.of() can't find one and throws).
      //
      // Localizations lookup needs a context — use the navigator's
      // own context for that (Localizations IS an ancestor of the
      // Navigator), with a fallback to the local context just in
      // case the navigator state isn't available yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext =
            sl<GlobalKey<NavigatorState>>().currentState?.context ?? context;
        AppSnackBar.showOnRoot(
          message: LocaleKeys.subscriptions_subscribe_success.t(navContext),
          type: SnackBarType.success,
        );
      });
    } else if (state is SubscriptionPurchaseFailure) {
      // Failure keeps the user on the checkout screen — the current
      // context's Overlay is the right binding, no deferral needed.
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}

class _PromoSection extends StatelessWidget {
  const _PromoSection();

  @override
  Widget build(BuildContext context) {
    // Reuses the existing cubit-wired DiscountCodeField verbatim —
    // wrapping it in a paper card aligns it visually with the other
    // checkout sections without touching its state machine.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s16,
        vertical: QeranSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.hairline),
      ),
      child: const DiscountCodeField(),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final double effectivePrice;
  final bool inflight;
  final bool disabled;
  final VoidCallback onTap;

  const _BottomCta({
    required this.effectivePrice,
    required this.inflight,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = LocaleKeys.subscriptions_currency.t(context);
    final priceLabel = '${effectivePrice.toStringAsFixed(2)} $currency';
    final confirmLabel = LocaleKeys.subscriptions_confirm_cta.t(context);
    return Container(
      decoration: const BoxDecoration(
        color: QeranColors.paper,
        boxShadow: [
          BoxShadow(
            color: QeranColors.wine08,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s12,
            QeranSpacing.s20,
            QeranSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: QeranSpacing.s8),
                child: Text(
                  'الإجمالي · $priceLabel',
                  textAlign: TextAlign.center,
                  style: QeranTypography.caption.copyWith(
                    color: QeranColors.inkMuted,
                  ),
                ),
              ),
              QeranButton(
                label: '$confirmLabel · $priceLabel',
                loading: inflight,
                onPressed: disabled ? null : onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
