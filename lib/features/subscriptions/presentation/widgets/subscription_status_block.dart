import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
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
import '../../domain/helpers/subscription_format.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/current/current_subscription_state.dart';
import 'plan_visual.dart';

/// Lives in the Profile tab. Renders four distinct emotional states
/// from the app-scoped `CurrentSubscriptionCubit`. Visuals only —
/// state shape and CTA targets are unchanged.
class SubscriptionStatusBlock extends StatelessWidget {
  const SubscriptionStatusBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentSubscriptionCubit, CurrentSubscriptionState>(
      builder: (context, state) {
        return switch (state) {
          CurrentSubscriptionInitial() ||
          CurrentSubscriptionLoading() =>
            const _LoadingCard(),
          CurrentSubscriptionLoaded(:final subscription) =>
            subscription.isCurrentlyActive
                ? _ActiveCard(subscription: subscription)
                : _ExpiredCard(subscription: subscription),
          CurrentSubscriptionNone() => const _PromoCard(),
          CurrentSubscriptionFailure(:final lastKnown) =>
            lastKnown != null && lastKnown.isCurrentlyActive
                ? _ActiveCard(subscription: lastKnown)
                : const _PromoCard(),
        };
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const QeranCard(
      child: SizedBox(
        height: 60,
        child: Center(child: QeranLoader()),
      ),
    );
  }
}

/// Wine-gradient hero with a gold ring motif behind the crown icon.
/// Used when the user has no active subscription — the visual weight
/// signals "this matters" without being loud.
class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: QeranRadii.panelR,
        boxShadow: QeranShadows.eHero,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      padding: const EdgeInsets.all(QeranSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _CrownBadge(),
              QeranSpacing.hs16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocaleKeys.subscriptions_status_not_subscribed_title
                          .t(context),
                      style: QeranTypography.title
                          .copyWith(color: QeranColors.paper),
                    ),
                    QeranSpacing.vs4,
                    Text(
                      LocaleKeys.subscriptions_status_not_subscribed_body
                          .t(context),
                      style: QeranTypography.bodySm
                          .copyWith(color: QeranColors.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          QeranSpacing.vs20,
          QeranButton(
            label: LocaleKeys.subscriptions_view_packages_cta.t(context),
            variant: QeranButtonVariant.primary,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () => NavigationManager.navigateTo(
              context,
              RouteNames.packagesScreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownBadge extends StatelessWidget {
  const _CrownBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const RingMotif(
            color: QeranColors.gold,
            opacity: 0.18,
            size: 56,
            ringCount: 1,
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.gold.withValues(alpha: 0.18),
              border: Border.all(color: QeranColors.gold, width: 1.2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: QeranColors.gold,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  final CurrentSubscription subscription;
  const _ExpiredCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: QeranColors.wine08,
            borderRadius: QeranRadii.controlR,
            border: Border.all(color: QeranColors.wine20),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: QeranColors.wine,
                size: 18,
              ),
              QeranSpacing.hs8,
              Expanded(child: _ExpiredCopy()),
            ],
          ),
        ),
        QeranSpacing.vs12,
        const _PromoCard(),
      ],
    );
  }
}

class _ExpiredCopy extends StatelessWidget {
  const _ExpiredCopy();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.subscriptions_status_expired_banner.t(context),
      style: QeranTypography.label,
    );
  }
}

/// Active subscription — paper card with a top gold accent bar,
/// hero row, hairline divider, restrained usage rows, and a quiet
/// "upgrade" secondary CTA.
class _ActiveCard extends StatelessWidget {
  final CurrentSubscription subscription;
  const _ActiveCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final accent = PlanVisual.parseColor(subscription.plan.color);
    final dateFmt = DateFormat.yMMMMd(context.locale.toString());
    final expiresAt = dateFmt.format(subscription.expiresAt);
    final daysRemaining = subscription.daysRemaining;
    final pricingLabel = subscription.pricing.labelAr ??
        subscription.pricing.labelEn ??
        LocaleKeys.subscriptions_duration_days.t(context).replaceFirst(
              '{days}',
              '${subscription.pricing.durationDays}',
            );

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
            // Top gold accent bar — quiet "premium" signal.
            Container(height: 3, color: QeranColors.gold),
            Padding(
              padding: const EdgeInsets.all(QeranSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _PlanBadge(plan: subscription.plan, accent: accent),
                      QeranSpacing.hs12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subscription.plan.nameAr,
                              style: QeranTypography.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            QeranSpacing.vs4,
                            Text(
                              pricingLabel,
                              style: QeranTypography.bodySm,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  QeranSpacing.vs16,
                  Text(
                    LocaleKeys.subscriptions_status_active_until
                        .t(context)
                        .replaceFirst('{date}', expiresAt),
                    style: QeranTypography.bodySm,
                  ),
                  if (daysRemaining >= 0) ...[
                    QeranSpacing.vs4,
                    Text(
                      LocaleKeys.subscriptions_status_days_remaining
                          .t(context)
                          .replaceFirst('{days}', '$daysRemaining'),
                      style: QeranTypography.caption,
                    ),
                  ],
                  QeranSpacing.vs16,
                  const _Hairline(),
                  QeranSpacing.vs16,
                  _UsageRow(
                    icon: Icons.favorite_rounded,
                    label: LocaleKeys.subscriptions_feature_likes_label
                        .t(context),
                    used: subscription.likesUsed,
                    remaining: subscription.likesRemaining,
                    allowed: subscription.plan.features.likesAllowed,
                  ),
                  _UsageRow(
                    icon: Icons.photo_camera_rounded,
                    label: LocaleKeys
                        .subscriptions_feature_photo_exchanges_label
                        .t(context),
                    used: subscription.photoExchangesUsed,
                    remaining: subscription.photoExchangesRemaining,
                    allowed: subscription
                        .plan.features.photoExchangesAllowed,
                  ),
                  _UsageRow(
                    icon: Icons.workspace_premium_rounded,
                    label: LocaleKeys
                        .subscriptions_feature_serious_interests_label
                        .t(context),
                    used: subscription.seriousInterestsUsed,
                    remaining: subscription.seriousInterestsRemaining,
                    allowed: subscription
                        .plan.features.seriousInterestsAllowed,
                  ),
                  _UnlimitedRow(
                    icon: Icons.visibility_rounded,
                    label: LocaleKeys
                        .subscriptions_feature_daily_profile_views_label
                        .t(context),
                    allowed: subscription
                        .plan.features.dailyProfileViewsAllowed,
                  ),
                  QeranSpacing.vs20,
                  QeranButton(
                    label: LocaleKeys.subscriptions_upgrade_cta.t(context),
                    variant: QeranButtonVariant.secondary,
                    size: QeranButtonSize.md,
                    onPressed: () => NavigationManager.navigateTo(
                      context,
                      RouteNames.packagesScreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: QeranColors.divider),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final dynamic plan;
  final Color accent;
  const _PlanBadge({required this.plan, required this.accent});

  @override
  Widget build(BuildContext context) {
    final icon = plan.icon as String;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold.withValues(alpha: 0.18),
        border: Border.all(color: QeranColors.gold, width: 1),
      ),
      alignment: Alignment.center,
      child: PlanVisual.isUrl(icon)
          ? ClipOval(
              child: Image.network(
                icon,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.workspace_premium_rounded,
                  color: QeranColors.wine,
                  size: 22,
                ),
              ),
            )
          : const Icon(
              Icons.workspace_premium_rounded,
              color: QeranColors.wine,
              size: 22,
            ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used;
  final int remaining;
  final int allowed;

  const _UsageRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.remaining,
    required this.allowed,
  });

  @override
  Widget build(BuildContext context) {
    final unlimited = CurrentSubscription.isUnlimitedRemaining(remaining);
    final total = unlimited ? 0 : used + remaining;
    final progress = SubscriptionFormat.usagePercent(used, total);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: QeranColors.wine),
              QeranSpacing.hs8,
              Expanded(
                child: Text(label, style: QeranTypography.bodySm),
              ),
              Text(
                unlimited
                    ? SubscriptionFormat.formatRemaining(context, remaining)
                    : '$used / $total',
                style: QeranTypography.numeric,
              ),
            ],
          ),
          if (!unlimited && total > 0) ...[
            const SizedBox(height: QeranSpacing.s6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: QeranColors.gold.withValues(alpha: 0.20),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  QeranColors.wine,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnlimitedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int allowed;
  const _UnlimitedRow({
    required this.icon,
    required this.label,
    required this.allowed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: QeranColors.wine),
          QeranSpacing.hs8,
          Expanded(child: Text(label, style: QeranTypography.bodySm)),
          Text(
            SubscriptionFormat.formatAllowed(context, allowed, ''),
            style: QeranTypography.label,
          ),
        ],
      ),
    );
  }
}
