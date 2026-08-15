import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/relative_time.dart';
import 'package:qeran/features/notifications/domain/entities/notification_action.dart';
import 'package:qeran/features/notifications/domain/entities/notification_type.dart';
import 'package:qeran/features/notifications/presentation/widgets/notification_inbox_tile.dart'
    show NotificationUnreadDot;
import 'package:qeran/features/notifications/presentation/widgets/notification_tile_visuals.dart';

import '../../domain/entities/matchmaker_notification.dart';

/// One inbox row — a flat pressable feed row matching the user-app
/// `NotificationInboxTile` exactly (paper rows separated by the shared
/// [NotificationInboxDivider]; no per-row card). Same tone families +
/// per-action icons (via the shared [NotificationTileVisuals]) + relative time
/// + layout as the user tile, and now the same unread treatment: an [isUnread]
/// row is LIFTED off the paper, bolds its title and carries the shared
/// [NotificationUnreadDot].
///
/// Unread is LOCAL and coarser than the user app's: the backend exposes no
/// read-state, and with no per-id endpoint the matchmaker inbox has no "mark
/// this one read" — a row is unread when it arrived since the last visit
/// (`MatchmakerNotificationReadCubit`).
///
/// The row body is intentionally mirrored (not extracted) from the user tile —
/// extracting a shared `NotificationRow` would edit the user tile, out of this
/// screen's scope; that dedup is a deferred cleanup for a separate commit.
class MatchmakerNotificationTile extends StatelessWidget {
  const MatchmakerNotificationTile({
    super.key,
    required this.notification,
    required this.isArabic,
    this.isUnread = false,
    this.onTap,
  });

  final MatchmakerNotification notification;
  final bool isArabic;

  /// Drives the unread treatment. Local state — see the class doc.
  final bool isUnread;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = QeranRelativeTime.format(notification.createdAt, context);
    return Material(
      // Surface and lift live on the Material, not on a box inside the InkWell,
      // so the press ripple still paints ABOVE them. Rows were transparent on
      // the cream canvas before; paper + lift is the user-app treatment.
      color: QeranColors.paper,
      elevation: isUnread ? 2 : 0,
      // Never the Material default black — overlays and shadows are dark wine
      // throughout the app.
      shadowColor: QeranColors.wine.withValues(alpha: 0.18),
      child: InkWell(
        onTap: onTap,
        splashColor: QeranColors.creamSurface,
        highlightColor: QeranColors.creamSurface.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s16,
            vertical: QeranSpacing.s12,
          ),
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
                            style: QeranTypography.subtitle.copyWith(
                              color: QeranColors.wine,
                              fontWeight: isUnread ? FontWeight.w700 : null,
                            ),
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
                        if (isUnread) ...[
                          QeranSpacing.hs8,
                          const NotificationUnreadDot(),
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
        ),
      ),
    );
  }
}

/// 44px circular icon-chip via the shared [NotificationTileVisuals]. The
/// matchmaker `type` maps 1:1 to the user-app [NotificationType] by name; the
/// per-action glyph comes from `data.action` (empty/old records → default).
class _LeadingChip extends StatelessWidget {
  const _LeadingChip({required this.notification});

  final MatchmakerNotification notification;

  @override
  Widget build(BuildContext context) {
    final type = NotificationType.fromWire(notification.type.name);
    final action =
        NotificationAction.fromWire(notification.data['action']?.toString());
    final style = NotificationTileVisuals.of(type, action);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: style.background,
        shape: BoxShape.circle,
      ),
      child: Icon(style.icon, color: style.foreground, size: 22),
    );
  }
}
