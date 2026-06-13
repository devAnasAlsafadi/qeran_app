import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/utils/relative_time.dart';

import '../../domain/entities/notification_action.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_type.dart';

/// One inbox row, on the design system. A 44px leading icon-chip whose TONE
/// signals meaning (not a rainbow), a title + relative-time top line, and a
/// 2-line body preview. No per-row unread dot — the backend exposes no
/// read-state (render only what the backend backs).
///
/// Tone families:
/// * **Match** — solid gold chip (the hero; most prominent).
/// * **Chat / Offer** — soft-gold chip.
/// * **Profile / Announcement / General** — wine-tint chip.
///
/// The icon varies by [NotificationType], and within `Match` by
/// [NotificationAction] (new like / mutual / photo-exchange / formal step).
/// Profile rejection stays calm — a neutral info icon in the wine tone, never
/// red (this is a respectful matrimony app).
class NotificationInboxTile extends StatelessWidget {
  const NotificationInboxTile({
    super.key,
    required this.notification,
    required this.isArabic,
    this.onTap,
  });

  final NotificationItem notification;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = QeranRelativeTime.format(notification.createdAt, context);
    return QeranCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: QeranSpacing.s12),
      padding: const EdgeInsets.all(QeranSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LeadingChip(notification: notification),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title(isArabic: isArabic),
                        textAlign: TextAlign.start,
                        style: QeranTypography.subtitle
                            .copyWith(color: QeranColors.wine),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (time != null) ...[
                      QeranSpacing.hs8,
                      Text(
                        time,
                        style: QeranTypography.caption
                            .copyWith(color: QeranColors.inkMuted),
                      ),
                    ],
                  ],
                ),
                QeranSpacing.vs4,
                Text(
                  notification.body(isArabic: isArabic),
                  textAlign: TextAlign.start,
                  style: QeranTypography.bodySm
                      .copyWith(color: QeranColors.inkBody),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The 44px circular icon-chip. Tone (background + foreground) is decided by
/// [_Tone.of]; the glyph by [_iconFor].
class _LeadingChip extends StatelessWidget {
  const _LeadingChip({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final tone = _Tone.of(notification.type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tone.background,
        shape: BoxShape.circle,
      ),
      child: Icon(_iconFor(notification), color: tone.foreground, size: 22),
    );
  }

  IconData _iconFor(NotificationItem n) {
    switch (n.type) {
      case NotificationType.match:
        return _matchIcon(n.action);
      case NotificationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.profile:
        return _profileIcon(n.action);
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.general:
      case NotificationType.unknown:
        return Icons.notifications_none_rounded;
    }
  }

  /// Within `Match`, the glyph tells the specific story.
  IconData _matchIcon(NotificationAction action) => switch (action) {
        NotificationAction.like => Icons.favorite_border_rounded,
        NotificationAction.likeAccepted => Icons.celebration_rounded,
        NotificationAction.photoExchangeRequested ||
        NotificationAction.photoExchangeAccepted ||
        NotificationAction.photoExchangeRejected =>
          Icons.photo_camera_outlined,
        NotificationAction.compatibilityCaseUpdated =>
          Icons.handshake_rounded,
        _ => Icons.favorite_rounded,
      };

  /// Profile approve/reject — both calm; rejection never wears red.
  IconData _profileIcon(NotificationAction action) => switch (action) {
        NotificationAction.profileApproved => Icons.verified_user_outlined,
        NotificationAction.profileRejected => Icons.info_outline_rounded,
        _ => Icons.person_outline_rounded,
      };
}

/// A chip tone pair (background + foreground), derived from the type.
class _Tone {
  const _Tone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  /// Solid gold = the Match hero. Soft gold = Chat / Offer. Wine tint =
  /// Profile / Announcement / General (and any unknown future type).
  static _Tone of(NotificationType type) => switch (type) {
        NotificationType.match =>
          const _Tone(background: QeranColors.gold, foreground: QeranColors.wine),
        NotificationType.chat || NotificationType.offer => const _Tone(
            background: QeranColors.gold20,
            foreground: QeranColors.goldDeep,
          ),
        NotificationType.profile ||
        NotificationType.announcement ||
        NotificationType.general ||
        NotificationType.unknown =>
          const _Tone(
            background: QeranColors.wine08,
            foreground: QeranColors.wine,
          ),
      };
}
