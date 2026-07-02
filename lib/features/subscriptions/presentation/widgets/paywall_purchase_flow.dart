import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/subscription_pricing.dart';
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

  /// Reacts to [PackagePurchaseCubit] transitions (paid + restore paths).
  void handlePurchaseState(BuildContext context, PackagePurchaseState state) {
    switch (state) {
      case PackagePurchaseSuccess():
        _toast(context, LocaleKeys.subscriptions_purchase_success,
            SnackBarType.success);
        Navigator.of(context).pop();
      case PackagePurchaseCancelled():
        context.read<PackagePurchaseCubit>().reset();
      case PackagePurchaseFailure(:final userMessage):
        _toast(context, userMessage, SnackBarType.error);
      // CodeValidation* states are consumed by the discount UI (Commit 6).
      default:
        break;
    }
  }

  /// CTA routing: free → `/subscribe`; same product → route to اشتراكي;
  /// otherwise a paid purchase (carrying [oldProductId] for upgrade proration).
  void handleCta(
    BuildContext context,
    SubscriptionPlan plan,
    SubscriptionPricing pricing,
  ) {
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
    context
        .read<PackagePurchaseCubit>()
        .purchase(pricing: pricing, oldProductId: currentProductId);
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
      (_) => _toast(context, LocaleKeys.subscriptions_purchase_failure,
          SnackBarType.error),
      (subscription) {
        sl<CurrentSubscriptionCubit>().onSubscribed(subscription);
        _toast(context, LocaleKeys.subscriptions_purchase_success,
            SnackBarType.success);
        Navigator.of(context).pop();
      },
    );
  }

  void _toast(BuildContext context, String key, SnackBarType type) =>
      AppSnackBar.show(context, message: key.t(context), type: type);
}
