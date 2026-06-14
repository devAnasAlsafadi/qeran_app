import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_card.dart';
import 'package:qeran/core/utils/relative_time.dart';

import '../../domain/entities/notification_item.dart';
import 'notification_tile_visuals.dart';

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

/// The 44px circular icon-chip. Tone (background + foreground) and glyph come
/// from the shared [NotificationTileVisuals] (same mapping as the matchmaker
/// inbox tile).
class _LeadingChip extends StatelessWidget {
  const _LeadingChip({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final style = NotificationTileVisuals.of(
      notification.type,
      notification.action,
    );
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
