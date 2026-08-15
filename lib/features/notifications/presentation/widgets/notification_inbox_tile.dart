import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/relative_time.dart';

import '../../domain/entities/notification_item.dart';
import 'notification_tile_visuals.dart';

/// One inbox row — a flat pressable feed row (rows sit on the cream canvas,
/// separated by hairline dividers; no per-row card). A 44px leading icon-chip
/// whose TONE signals meaning (not a rainbow), a title + relative-time top
/// line, and a 2-line body preview.
///
/// Every row is paper. An [isUnread] one is LIFTED off it — a soft wine
/// elevation — and bolds its title and carries a gold dot, the house unread
/// marker (see `MatchmakerCountBadge`), never Material red. Unread used to be
/// a cream wash instead; against the cream canvas behind the feed that read as
/// two tones of the same beige rather than as a state. Read-state is LOCAL:
/// the backend exposes none, so it comes from [NotificationReadCubit], not
/// from the payload.
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
    this.isUnread = false,
    this.onTap,
  });

  final NotificationItem notification;
  final bool isArabic;

  /// Drives the unread treatment. Local state — see the class doc.
  final bool isUnread;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = QeranRelativeTime.format(notification.createdAt, context);
    return Material(
      // Surface and lift live on the Material, not on a box inside the InkWell,
      // so the press ripple still paints ABOVE them.
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

/// The unread marker: a small gold disc, matching `MatchmakerCountBadge`'s
/// "gold, never Material red" convention. Sized to sit on the title line
/// without pushing it around.
class NotificationUnreadDot extends StatelessWidget {
  const NotificationUnreadDot({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: QeranColors.gold,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Hairline divider between feed rows, indented past the 44px leading chip +
/// 12px gap so the line aligns under the row text, not the badge.
class NotificationInboxDivider extends StatelessWidget {
  const NotificationInboxDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.only(start: 72, end: 16),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: QeranColors.divider),
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
