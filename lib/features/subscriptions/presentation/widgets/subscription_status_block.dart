import 'package:easy_localization/easy_localization.dart';
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

import '../../domain/entities/current_subscription.dart';
import '../../domain/helpers/subscription_format.dart';
import '../blocs/current/current_subscription_cubit.dart';
import '../blocs/current/current_subscription_state.dart';
import 'plan_visual.dart';

/// Lives in the Profile tab above the logout tile. Renders four
/// distinct visual states from the app-scoped `CurrentSubscriptionCubit`:
///
/// * `Loading` / `Initial`  → slim placeholder card
/// * `None`                 → "discover packages" promo
/// * `Loaded` and active    → premium summary with usage rows
/// * `Loaded` but expired   → renewal banner above a promo card
/// * `Failure`              → soft error with a retry tap
///
/// Tapping any CTA pushes `RouteNames.packagesScreen`.
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
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _PromoBadge(),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.subscriptions_status_not_subscribed_title
                          .t(context),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.subscriptions_status_not_subscribed_body
                          .t(context),
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
          CustomButton(
            text: LocaleKeys.subscriptions_view_packages_cta.t(context),
            backgroundColor: AppColors.primary,
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

class _PromoBadge extends StatelessWidget {
  const _PromoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.diamond_outlined,
        color: AppColors.primary,
        size: 22,
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
            horizontal: AppDimens.p16,
            vertical: AppDimens.p12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: AppDimens.p8),
              Expanded(
                child: Text(
                  LocaleKeys.subscriptions_status_expired_banner.t(context),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimens.p12),
        const _PromoCard(),
      ],
    );
  }
}

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

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PlanBadge(plan: subscription.plan, accent: accent),
              const SizedBox(width: AppDimens.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            subscription.plan.nameAr,
                            style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $pricingLabel',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      LocaleKeys.subscriptions_status_active_until
                          .t(context)
                          .replaceFirst('{date}', expiresAt),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (daysRemaining >= 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        LocaleKeys.subscriptions_status_days_remaining
                            .t(context)
                            .replaceFirst('{days}', '$daysRemaining'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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
          const SizedBox(height: AppDimens.p12),
          _UsageRow(
            icon: Icons.favorite_rounded,
            label: LocaleKeys.subscriptions_feature_likes_label.t(context),
            used: subscription.likesUsed,
            remaining: subscription.likesRemaining,
            allowed: subscription.plan.features.likesAllowed,
          ),
          _UsageRow(
            icon: Icons.photo_camera_rounded,
            label: LocaleKeys.subscriptions_feature_photo_exchanges_label
                .t(context),
            used: subscription.photoExchangesUsed,
            remaining: subscription.photoExchangesRemaining,
            allowed: subscription.plan.features.photoExchangesAllowed,
          ),
          _UsageRow(
            icon: Icons.workspace_premium_rounded,
            label: LocaleKeys.subscriptions_feature_serious_interests_label
                .t(context),
            used: subscription.seriousInterestsUsed,
            remaining: subscription.seriousInterestsRemaining,
            allowed: subscription.plan.features.seriousInterestsAllowed,
          ),
          _UnlimitedRow(
            icon: Icons.visibility_rounded,
            label: LocaleKeys.subscriptions_feature_daily_profile_views_label
                .t(context),
            allowed: subscription.plan.features.dailyProfileViewsAllowed,
          ),
          const SizedBox(height: AppDimens.p16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.30),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: AppDimens.p12),
            ),
            onPressed: () => NavigationManager.navigateTo(
              context,
              RouteNames.packagesScreen,
            ),
            child: Text(
              LocaleKeys.subscriptions_upgrade_cta.t(context),
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

class _PlanBadge extends StatelessWidget {
  final dynamic plan;
  final Color accent;
  const _PlanBadge({required this.plan, required this.accent});

  @override
  Widget build(BuildContext context) {
    final icon = (plan.icon as String).isEmpty ? '💎' : plan.icon as String;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: PlanVisual.isUrl(icon)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                icon,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.workspace_premium_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
            )
          : Text(icon, style: const TextStyle(fontSize: 22)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: AppDimens.p8),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                unlimited
                    ? SubscriptionFormat.formatRemaining(context, remaining)
                    : '$used / $total',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (!unlimited && total > 0) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimens.p8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            SubscriptionFormat.formatAllowed(context, allowed, ''),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.p20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F431C33),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
