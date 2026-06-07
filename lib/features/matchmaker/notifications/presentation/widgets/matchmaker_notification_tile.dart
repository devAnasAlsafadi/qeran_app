import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_card.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_notification.dart';

/// One inbox row — DS-token clone of the legacy `notification_tile` layout
/// (leading type icon + title + body + time). No per-row unread dot: the
/// backend exposes no read-state, so the only unread signal is the bell badge
/// (rule: render only what the backend backs).
class MatchmakerNotificationTile extends StatelessWidget {
  const MatchmakerNotificationTile({
    super.key,
    required this.notification,
    required this.isArabic,
    this.onTap,
  });

  final MatchmakerNotification notification;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = _time(context);
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeadingIcon(type: notification.type),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.title(isArabic: isArabic),
                  style: QeranTypography.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                QeranSpacing.vs4,
                Text(
                  notification.body(isArabic: isArabic),
                  style:
                      QeranTypography.bodySm.copyWith(color: QeranColors.inkBody),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (time != null) ...[
                  QeranSpacing.vs8,
                  Text(
                    time,
                    style: QeranTypography.caption
                        .copyWith(color: QeranColors.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact relative time (now / Nm / Nh / Nd → short date), reusing the
  /// conversations time tokens.
  String? _time(BuildContext context) {
    final at = notification.createdAt;
    if (at == null) return null;
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) {
      return LocaleKeys.matchmaker_conversations_time_now.t(context);
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}'
          '${LocaleKeys.matchmaker_conversations_time_minute.t(context)}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}'
          '${LocaleKeys.matchmaker_conversations_time_hour.t(context)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}'
          '${LocaleKeys.matchmaker_conversations_time_day.t(context)}';
    }
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$d';
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.type});

  final MatchmakerNotificationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: QeranColors.wine08,
        borderRadius: QeranRadii.pill,
      ),
      child: Icon(_iconFor(type), color: QeranColors.wine, size: 20),
    );
  }

  IconData _iconFor(MatchmakerNotificationType type) => switch (type) {
        MatchmakerNotificationType.chat => Icons.chat_bubble_outline_rounded,
        MatchmakerNotificationType.match => Icons.favorite_border_rounded,
        MatchmakerNotificationType.profile => Icons.person_outline_rounded,
        MatchmakerNotificationType.announcement => Icons.campaign_outlined,
        MatchmakerNotificationType.offer => Icons.local_offer_outlined,
        MatchmakerNotificationType.general ||
        MatchmakerNotificationType.unknown =>
          Icons.notifications_none_rounded,
      };
}
