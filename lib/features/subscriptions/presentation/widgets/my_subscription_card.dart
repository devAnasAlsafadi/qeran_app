import 'package:flutter/material.dart';
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

import '../../domain/entities/current_subscription.dart';
import '../../domain/entities/subscription_features.dart';
import 'my_subscription_parts.dart';
import 'subscription_entitlement_row.dart';

/// The active (and expiring-soon) My-subscription card: a plan hero + a
/// days-remaining ring, the "remaining this cycle" entitlement centerpiece, and
/// the upgrade / renew actions. Pure presentation — all data comes from the
/// passed [subscription] (from `/current`); [expiring] swaps the accent + CTA
/// order and surfaces a gentle renewal notice.
class MySubscriptionCard extends StatelessWidget {
  final CurrentSubscription subscription;
  final bool expiring;

  const MySubscriptionCard({
    super.key,
    required this.subscription,
    required this.expiring,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.e2,
      ),
      child: ClipRRect(
        borderRadius: QeranRadii.cardR,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 3, color: QeranColors.gold),
            Padding(
              padding: const EdgeInsets.all(QeranSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  MySubscriptionHero(
                    subscription: subscription,
                    expiring: expiring,
                  ),
                  if (expiring) ...[
                    QeranSpacing.vs16,
                    const MySubscriptionExpiringNotice(),
                  ],
                  QeranSpacing.vs20,
                  Text(
                    LocaleKeys.subscriptions_status_remaining_this_cycle
                        .t(context),
                    style: QeranTypography.label
                        .copyWith(color: QeranColors.inkStrong),
                  ),
                  QeranSpacing.vs8,
                  ..._entitlementRows(context, subscription),
                  QeranSpacing.vs20,
                  ..._ctas(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ctas(BuildContext context) {
    void toPlans() =>
        NavigationManager.navigateTo(context, RouteNames.packagesScreen);
    final upgrade = QeranButton(
      label: LocaleKeys.subscriptions_upgrade_cta.t(context),
      variant:
          expiring ? QeranButtonVariant.secondary : QeranButtonVariant.primary,
      size: QeranButtonSize.md,
      onPressed: toPlans,
    );
    final renew = QeranButton(
      label: LocaleKeys.subscriptions_renew_subscription.t(context),
      variant:
          expiring ? QeranButtonVariant.primary : QeranButtonVariant.secondary,
      size: QeranButtonSize.md,
      onPressed: toPlans,
    );
    return expiring
        ? [renew, QeranSpacing.vs12, upgrade]
        : [upgrade, QeranSpacing.vs12, renew];
  }

  List<Widget> _entitlementRows(BuildContext context, CurrentSubscription s) {
    final f = s.plan.features;
    return [
      _metered(context, Icons.favorite_rounded,
          LocaleKeys.subscriptions_feature_likes_label.t(context),
          allowed: f.likesAllowed,
          used: s.likesUsed,
          remaining: s.likesRemaining),
      _metered(context, Icons.handshake_rounded,
          LocaleKeys.subscriptions_feature_serious_interests_label.t(context),
          allowed: f.seriousInterestsAllowed,
          used: s.seriousInterestsUsed,
          remaining: s.seriousInterestsRemaining),
      _metered(context, Icons.photo_library_rounded,
          LocaleKeys.subscriptions_feature_photo_exchanges_label.t(context),
          allowed: f.photoExchangesAllowed,
          used: s.photoExchangesUsed,
          remaining: s.photoExchangesRemaining),
      // Daily views: `/current` carries no remaining counter — show the plan
      // allowance (or unlimited) rather than fabricate a used/total.
      _allowance(context, Icons.visibility_rounded,
          LocaleKeys.subscriptions_feature_daily_profile_views_label.t(context),
          allowed: f.dailyProfileViewsAllowed),
    ];
  }

  Widget _metered(
    BuildContext context,
    IconData icon,
    String label, {
    required int allowed,
    required int used,
    required int remaining,
  }) {
    final unlimited = SubscriptionFeatures.isUnlimited(allowed) ||
        CurrentSubscription.isUnlimitedRemaining(remaining);
    if (unlimited) {
      return SubscriptionEntitlementRow(
        icon: icon,
        label: label,
        unlimited: true,
        valueText: LocaleKeys.subscriptions_unlimited.t(context),
      );
    }
    final total = used + remaining;
    final countText = LocaleKeys.subscriptions_status_remaining_of
        .t(context)
        .replaceFirst('{remaining}', '$remaining')
        .replaceFirst('{total}', '$total');
    final leftText = LocaleKeys.subscriptions_status_remaining_left.t(context);
    return SubscriptionEntitlementRow(
      icon: icon,
      label: label,
      valueText: '$countText $leftText',
      barFraction: total > 0 ? remaining / total : 0.0,
    );
  }

  Widget _allowance(
    BuildContext context,
    IconData icon,
    String label, {
    required int allowed,
  }) {
    if (SubscriptionFeatures.isUnlimited(allowed)) {
      return SubscriptionEntitlementRow(
        icon: icon,
        label: label,
        unlimited: true,
        valueText: LocaleKeys.subscriptions_unlimited.t(context),
      );
    }
    return SubscriptionEntitlementRow(
      icon: icon,
      label: label,
      valueText: LocaleKeys.subscriptions_status_per_day
          .t(context)
          .replaceFirst('{count}', '$allowed'),
    );
  }
}
