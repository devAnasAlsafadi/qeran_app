import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/current/current_subscription_cubit.dart';
import 'paywall_intent.dart';

/// Premium burgundy/cream sheet shown when a gated action is blocked.
/// Dismissible — the user can close it and keep browsing Discovery.
/// CTA pushes the packages route.
Future<void> showPaywall(
  BuildContext context, {
  required PaywallIntent intent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    barrierColor: const Color(0x59431C33),
    useSafeArea: true,
    builder: (_) => _PaywallSheet(intent: intent),
  );
}

class _PaywallSheet extends StatelessWidget {
  final PaywallIntent intent;
  const _PaywallSheet({required this.intent});

  @override
  Widget build(BuildContext context) {
    final hasActive = context.select<CurrentSubscriptionCubit, bool>(
      (c) => c.hasActiveSubscription,
    );
    final copy = _copyFor(intent, hasActive);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33431C33),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.p24,
        AppDimens.p12,
        AppDimens.p24,
        AppDimens.p24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DragHandle(),
          const SizedBox(height: AppDimens.p20),
          _BadgeIcon(intent: intent),
          const SizedBox(height: AppDimens.p16),
          Text(
            copy.title.t(context),
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            copy.body.t(context),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppDimens.p24),
          CustomButton(
            text: (hasActive
                    ? LocaleKeys.subscriptions_upgrade_cta
                    : LocaleKeys.subscriptions_view_packages_cta)
                .t(context),
            backgroundColor: AppColors.primary,
            onPressed: () {
              Navigator.of(context).pop();
              NavigationManager.navigateTo(
                context,
                RouteNames.packagesScreen,
              );
            },
          ),
          const SizedBox(height: AppDimens.p8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocaleKeys.subscriptions_paywall_not_now.t(context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _PaywallCopy _copyFor(PaywallIntent intent, bool hasActive) {
    return switch (intent) {
      PaywallIntent.like => hasActive
          ? const _PaywallCopy(
              title: LocaleKeys.subscriptions_paywall_likes_exhausted_title,
              body: LocaleKeys.subscriptions_paywall_likes_exhausted_body,
            )
          : const _PaywallCopy(
              title: LocaleKeys.subscriptions_paywall_like_title,
              body: LocaleKeys.subscriptions_paywall_like_body,
            ),
      PaywallIntent.seriousInterest => const _PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_serious_interest_title,
          body: LocaleKeys.subscriptions_paywall_serious_interest_body,
        ),
      PaywallIntent.photoExchange => const _PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_photo_title,
          body: LocaleKeys.subscriptions_paywall_photo_body,
        ),
      PaywallIntent.acceptLike => const _PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_accept_title,
          body: LocaleKeys.subscriptions_paywall_accept_body,
        ),
      PaywallIntent.promo => const _PaywallCopy(
          title: LocaleKeys.subscriptions_status_not_subscribed_title,
          body: LocaleKeys.subscriptions_status_not_subscribed_body,
        ),
    };
  }
}

class _PaywallCopy {
  final String title;
  final String body;
  const _PaywallCopy({required this.title, required this.body});
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final PaywallIntent intent;
  const _BadgeIcon({required this.intent});

  @override
  Widget build(BuildContext context) {
    final icon = switch (intent) {
      PaywallIntent.like => Icons.favorite_rounded,
      PaywallIntent.seriousInterest => Icons.workspace_premium_rounded,
      PaywallIntent.photoExchange => Icons.photo_camera_rounded,
      PaywallIntent.acceptLike => Icons.handshake_rounded,
      PaywallIntent.promo => Icons.diamond_outlined,
    };
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 30, color: AppColors.primary),
      ),
    );
  }
}
