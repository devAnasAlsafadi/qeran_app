import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/current_subscription.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/current/current_subscription_state.dart';
import 'my_subscription_card.dart';
import 'subscription_free_card.dart';

/// Lives on the My-subscription screen (اشتراكي). Renders the app-scoped
/// [CurrentSubscriptionCubit] into one of five states: active / expiring-soon
/// (both via [MySubscriptionCard]), expired, on-Free (our `/current`-null
/// mapping), and loading/error. Visuals only — the cubit owns fetch + refresh.
class SubscriptionStatusBlock extends StatelessWidget {
  const SubscriptionStatusBlock({super.key});

  /// A subscription with this many days (or fewer) left renders the gentle
  /// expiring-soon variant instead of the plain active card.
  static const int _expiringThresholdDays = 7;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
      builder: (context, state) {
        return switch (state) {
          CurrentSubscriptionInitial() ||
          CurrentSubscriptionLoading() =>
            const _LoadingCard(),
          CurrentSubscriptionLoaded(:final subscription) =>
            _forSubscription(subscription),
          // `/current` returned null → NO subscription yet (NOT "on Free"). The
          // card invites activating the free trial or picking a plan.
          CurrentSubscriptionNone() => const SubscriptionFreeCard(),
          CurrentSubscriptionFailure(:final lastKnown) => lastKnown != null
              ? _forSubscription(lastKnown)
              : const _ErrorCard(),
        };
      },
    );
  }

  Widget _forSubscription(CurrentSubscription sub) {
    // A missing/unparseable expiry is an UNKNOWN state, not an expiry — show the
    // error/retry card rather than mislabel a data problem as "expired".
    if (!sub.hasReliableExpiry) return const _ErrorCard();
    if (!sub.isCurrentlyActive) return const _ExpiredCard();
    return MySubscriptionCard(
      subscription: sub,
      expiring: sub.daysRemaining <= _expiringThresholdDays,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const QeranCard(
      child: SizedBox(height: 120, child: Center(child: QeranLoader())),
    );
  }
}

/// Expired subscription — a quiet banner + a renew action.
class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard();

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: QeranColors.wine, size: 20),
              QeranSpacing.hs8,
              Expanded(
                child: Text(
                  LocaleKeys.subscriptions_status_expired_banner.t(context),
                  style: QeranTypography.bodySm,
                ),
              ),
            ],
          ),
          QeranSpacing.vs16,
          QeranButton(
            label: LocaleKeys.subscriptions_renew_subscription.t(context),
            variant: QeranButtonVariant.primary,
            size: QeranButtonSize.md,
            onPressed: () =>
                NavigationManager.navigateTo(context, RouteNames.packagesScreen),
          ),
        ],
      ),
    );
  }
}

/// Transport/parse error with no cached subscription to fall back on.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return QeranCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.subscriptions_load_failed.t(context),
            style: QeranTypography.bodySm,
            textAlign: TextAlign.center,
          ),
          QeranSpacing.vs12,
          QeranButton(
            label: LocaleKeys.subscriptions_retry.t(context),
            variant: QeranButtonVariant.secondary,
            size: QeranButtonSize.md,
            onPressed: () =>
                context.read<CurrentSubscriptionCubit>().refresh(force: true),
          ),
        ],
      ),
    );
  }
}
