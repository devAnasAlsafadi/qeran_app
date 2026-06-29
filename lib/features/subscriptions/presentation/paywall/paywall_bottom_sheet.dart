import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/current/current_subscription_cubit.dart';
import 'paywall_intent.dart';

/// Premium paper/wine sheet shown when a gated action is blocked.
/// Dismissible — the user can close it and keep browsing Discovery.
/// CTA pushes the packages route.
Future<void> showPaywall(
  BuildContext context, {
  required PaywallIntent intent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
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
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.domeTop,
        boxShadow: QeranShadows.e3,
      ),
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s24,
        QeranSpacing.s12,
        QeranSpacing.s24,
        QeranSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DragHandle(),
          QeranSpacing.vs20,
          _BadgeIcon(intent: intent),
          QeranSpacing.vs16,
          Text(
            copy.title.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.headline,
          ),
          QeranSpacing.vs8,
          Text(
            copy.body.t(context),
            textAlign: TextAlign.center,
            style: QeranTypography.body,
          ),
          QeranSpacing.vs24,
          QeranButton(
            label: (hasActive
                    ? LocaleKeys.subscriptions_upgrade_cta
                    : LocaleKeys.subscriptions_view_packages_cta)
                .t(context),
            variant: QeranButtonVariant.primary,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              NavigationManager.navigateTo(
                context,
                RouteNames.packagesScreen,
              );
            },
          ),
          QeranSpacing.vs8,
          QeranButton(
            label: LocaleKeys.subscriptions_paywall_not_now.t(context),
            variant: QeranButtonVariant.ghost,
            size: QeranButtonSize.md,
            onPressed: () => Navigator.of(context).pop(),
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
      PaywallIntent.photoExchange => const _PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_photo_title,
          body: LocaleKeys.subscriptions_paywall_photo_body,
        ),
      PaywallIntent.acceptLike => const _PaywallCopy(
          title: LocaleKeys.subscriptions_paywall_accept_title,
          body: LocaleKeys.subscriptions_paywall_accept_body,
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
          color: QeranColors.wine.withValues(alpha: 0.25),
          borderRadius: QeranRadii.pill,
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
      PaywallIntent.photoExchange => Icons.photo_camera_rounded,
      PaywallIntent.acceptLike => Icons.handshake_rounded,
    };
    return Center(
      child: SizedBox(
        width: 140,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const IgnorePointer(
              child: RingMotif(
                color: QeranColors.gold,
                opacity: 0.10,
                size: 140,
                ringCount: 2,
                spacing: 14,
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: QeranColors.gold20,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 32, color: QeranColors.wine),
            ),
          ],
        ),
      ),
    );
  }
}
