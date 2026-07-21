import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
import '../../domain/entities/validate_code_response.dart';
import '../../domain/usecases/subscribe_usecase.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/purchase/package_purchase_cubit.dart';
import '../blocs/purchase/package_purchase_state.dart';

/// Purchase-flow logic for the packages screen, split out of the widget so the
/// coordinator stays a thin composer. Mixed onto the screen's [State] for
/// `setState` / `mounted` access; every UI entry takes the [BuildContext].
mixin PaywallPurchaseFlow<T extends StatefulWidget> on State<T> {
  /// True while a free-tier `/subscribe` call is in flight (drives the CTA
  /// spinner). Paid-purchase progress is driven by [PackagePurchaseCubit].
  bool freeBusy = false;

  /// The plan the user is buying, captured at CTA so the success screen can
  /// render it without waiting on `/current`. Null on the restore path (no
  /// selection) — the success screen degrades gracefully.
  SubscriptionPlan? _purchasedPlan;

  /// Pricing + any applied discount captured at CTA so a "Retry" from the
  /// failure screen can re-fire the EXACT same purchase without the user
  /// re-selecting a plan or re-entering the code.
  SubscriptionPricing? _purchasedPricing;
  ValidateCodeResponse? _purchasedValidatedCode;

  /// Reacts to [PackagePurchaseCubit] transitions (paid + restore paths).
  void handlePurchaseState(BuildContext context, PackagePurchaseState state) {
    switch (state) {
      case PackagePurchaseSuccess():
        NavigationManager.navigateAndReplace(
          context,
          RouteNames.purchaseSuccess,
          arguments: _purchasedPlan,
        );
      case PackagePurchaseCancelled():
        context.read<PackagePurchaseCubit>().reset();
      case PackagePurchaseFailure(:final userMessage):
        unawaited(_showPurchaseFailure(context, userMessage));
      // CodeValidation* states are consumed by the discount UI (Commit 6).
      default:
        break;
    }
  }

  /// Shows the failure screen carrying the SPECIFIC mapped [messageKey]. On
  /// "Retry" (screen pops `true`) it re-fires the same purchase; "Back" (pops
  /// `false`/`null`) just returns to the packages screen.
  Future<void> _showPurchaseFailure(
    BuildContext context,
    String messageKey,
  ) async {
    final retry = await NavigationManager.navigateTo(
      context,
      RouteNames.purchaseFailure,
      arguments: messageKey,
    );
    if (retry != true || !context.mounted) return;
    final pricing = _purchasedPricing;
    if (pricing == null) return;
    _firePaidPurchase(context, pricing);
  }

  /// CTA routing: free → `/subscribe`; same product → route to اشتراكي;
  /// otherwise a paid purchase (carrying [oldProductId] for upgrade proration).
  void handleCta(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionPricing pricing,
  ) {
    // Approval BEFORE subscription — a not-yet-approved profile can't subscribe
    // (free OR paid); the backend also rejects /subscribe with
    // PROFILE_NOT_APPROVED. The pre-gate banner explains why.
    if (context.read<ProfileGateCubit>().isGated) {
      _toast(context, LocaleKeys.profile_status_pending_review,
          SnackBarType.notice);
      return;
    }
    _purchasedPlan = plan;
    _purchasedPricing = pricing;
    if (plan.isFree || pricing.price == 0) {
      _subscribeFree(context, pricing);
      return;
    }
    final currentProductId =
        sl<CurrentSubscriptionCubit>().subscription?.pricing.googleProductId;
    if (currentProductId != null &&
        currentProductId == pricing.googleProductId) {
      _toast(context, LocaleKeys.subscriptions_already_subscribed_to_this_plan,
          SnackBarType.notice);
      NavigationManager.navigateTo(context, RouteNames.subscriptionDetails);
      return;
    }
    // Carry an applied discount into the purchase: an offer id on Android, the
    // full StoreKit signature on iOS (iOS is locked anyway — defensive).
    // Captured on the mixin so a Retry from the failure screen re-fires with
    // the same discount.
    final purchaseState = context.read<PackagePurchaseCubit>().state;
    _purchasedValidatedCode =
        purchaseState is PackagePurchaseCodeValidationSuccess &&
                (Platform.isAndroid || purchaseState.response.hasIosSignature)
            ? purchaseState.response
            : null;
    _firePaidPurchase(context, pricing);
  }

  /// Fires (or re-fires on Retry) the paid purchase with the captured discount
  /// and the current upgrade-proration product id.
  void _firePaidPurchase(BuildContext context, SubscriptionPricing pricing) {
    final currentProductId =
        sl<CurrentSubscriptionCubit>().subscription?.pricing.googleProductId;
    context.read<PackagePurchaseCubit>().purchase(
          pricing: pricing,
          validatedCode: _purchasedValidatedCode,
          oldProductId: currentProductId,
        );
  }

  /// Free tier (`isFree` / price 0) — activates via `/subscribe`, never RC.
  Future<void> _subscribeFree(
    BuildContext context,
    SubscriptionPricing pricing,
  ) async {
    setState(() => freeBusy = true);
    final result = await sl<SubscribeUseCase>()(pricingId: pricing.id);
    if (!mounted) return;
    setState(() => freeBusy = false);
    result.fold(
      (_) => NavigationManager.navigateTo(context, RouteNames.purchaseFailure),
      (subscription) {
        sl<CurrentSubscriptionCubit>().onSubscribed(subscription);
        // Free-tier plan comes straight from the `/subscribe` response — the
        // server's own truth, still never from `/current`.
        NavigationManager.navigateAndReplace(
          context,
          RouteNames.purchaseSuccess,
          arguments: subscription.plan,
        );
      },
    );
  }

  void _toast(BuildContext context, String key, SnackBarType type) =>
      AppSnackBar.show(context, message: key.t(context), type: type);
}
