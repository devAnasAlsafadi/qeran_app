import 'dart:math';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/current_subscription.dart';
import 'days_remaining_painter.dart';

/// The My-subscription card's plan hero: the days-remaining ring beside the
/// plan name + "renews on {date}". The ring accent deepens for [expiring].
class MySubscriptionHero extends StatelessWidget {
  final CurrentSubscription subscription;
  final bool expiring;
  const MySubscriptionHero({
    super.key,
    required this.subscription,
    required this.expiring,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final dateFmt = DateFormat.yMMMMd(context.locale.toString());
    final days = max(0, subscription.daysRemaining);
    final totalDays = subscription.pricing.durationDays > 0
        ? subscription.pricing.durationDays
        : max(1,
            subscription.expiresAt.difference(subscription.startsAt).inDays);

    return Row(
      children: [
        _DaysRing(
          days: days,
          progress: (days / totalDays).clamp(0.0, 1.0),
          arcColor: expiring ? QeranColors.goldDeep : QeranColors.gold,
        ),
        QeranSpacing.hs16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subscription.plan.name(isArabic: isArabic),
                style: QeranTypography.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              QeranSpacing.vs4,
              Text(
                LocaleKeys.subscriptions_status_active_until
                    .t(context)
                    .replaceFirst(
                        '{date}', dateFmt.format(subscription.expiresAt)),
                style:
                    QeranTypography.bodySm.copyWith(color: QeranColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaysRing extends StatelessWidget {
  final int days;
  final double progress;
  final Color arcColor;
  const _DaysRing({
    required this.days,
    required this.progress,
    required this.arcColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: DaysRemainingPainter(progress: progress, arcColor: arcColor),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                textDirection: TextDirection.ltr,
                style: QeranTypography.displaySm
                    .copyWith(color: QeranColors.inkStrong),
              ),
              Text(
                LocaleKeys.subscriptions_status_day_unit.t(context),
                style:
                    QeranTypography.caption.copyWith(color: QeranColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The gentle amber-toned renewal nudge shown above the entitlements when the
/// subscription is close to expiry.
class MySubscriptionExpiringNotice extends StatelessWidget {
  const MySubscriptionExpiringNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.goldPending,
        borderRadius: QeranRadii.controlR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded,
              size: 18, color: QeranColors.goldDeep),
          QeranSpacing.hs8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.subscriptions_expiring_title.t(context),
                  style: QeranTypography.label
                      .copyWith(color: QeranColors.inkStrong),
                ),
                QeranSpacing.vs4,
                Text(
                  LocaleKeys.subscriptions_expiring_msg.t(context),
                  style: QeranTypography.caption
                      .copyWith(color: QeranColors.inkBody),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
