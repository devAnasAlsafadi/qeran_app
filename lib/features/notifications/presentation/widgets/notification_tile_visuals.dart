import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

import '../../domain/entities/notification_action.dart';
import '../../domain/entities/notification_type.dart';

/// The leading-chip style for one notification row: tone (background +
/// foreground) plus the glyph. Shared by the user-app and matchmaker inbox
/// tiles so both render the same design-system treatment.
class NotificationTileStyle {
  const NotificationTileStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

/// Maps a notification's [NotificationType] (+ its [NotificationAction] for the
/// overloaded `Match` / `Profile` types) to a [NotificationTileStyle].
///
/// Tone families: Match = solid gold (the hero); Chat + Offer = soft gold;
/// Profile + Announcement + General (+ unknown) = wine tint. Within `Match`
/// the glyph tells the specific story; profile approve/reject stay calm —
/// rejection never wears red (respectful matrimony app).
class NotificationTileVisuals {
  const NotificationTileVisuals._();

  static NotificationTileStyle of(
    NotificationType type,
    NotificationAction action,
  ) {
    final (background, foreground) = _tone(type);
    return NotificationTileStyle(
      background: background,
      foreground: foreground,
      icon: _icon(type, action),
    );
  }

  static (Color background, Color foreground) _tone(NotificationType type) =>
      switch (type) {
        NotificationType.match => (QeranColors.gold, QeranColors.wine),
        NotificationType.chat ||
        NotificationType.offer =>
          (QeranColors.gold20, QeranColors.goldDeep),
        NotificationType.profile ||
        NotificationType.announcement ||
        NotificationType.general ||
        NotificationType.unknown =>
          (QeranColors.wine08, QeranColors.wine),
      };

  static IconData _icon(NotificationType type, NotificationAction action) {
    switch (type) {
      case NotificationType.match:
        return _matchIcon(action);
      case NotificationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.offer:
        return Icons.sell_outlined;
      case NotificationType.profile:
        return _profileIcon(action);
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.general:
      case NotificationType.unknown:
        return Icons.notifications_none_rounded;
    }
  }

  /// Within `Match`, the glyph tells the specific story — and the fallback
  /// deliberately tells NONE.
  ///
  /// It used to be a filled heart, which reads as "someone liked you". That is
  /// a specific claim, and `Match` covers events where it is simply false. The
  /// V2 events — the formal step and the ways a case ends — now have typed
  /// members drawn from the server's own verbatim strings, but an action this
  /// build has never heard of still resolves to the same glyph an unrecognised
  /// TYPE uses: unknown looks like unknown at both levels, and the server's own
  /// title and body carry the meaning.
  ///
  /// ⚠️ EXHAUSTIVE, and the wildcard it replaced is the point. `none` reaching
  /// the neutral bell is the intended behaviour and is spelled by name; a
  /// FUTURE member reaching it silently was not, and that is what a `_` arm
  /// could not tell apart. `profileApproved` / `profileRejected` are listed
  /// because the wire pairs type and action independently — a mismatched pair
  /// must resolve rather than throw — not because they are reachable here.
  ///
  /// The two endings wear different glyphs on purpose. A declined formal step
  /// and a called-off case are different events, and this feature's own rule
  /// is that an ending never borrows the nearest-looking member. Neither wears
  /// danger: rejection stays calm here as it does on the profile side.
  static IconData _matchIcon(NotificationAction action) => switch (action) {
        NotificationAction.like => Icons.favorite_border_rounded,
        NotificationAction.likeAccepted => Icons.celebration_rounded,
        NotificationAction.photoExchangeRequested ||
        NotificationAction.photoExchangeAccepted ||
        NotificationAction.photoExchangeRejected =>
          Icons.photo_camera_outlined,
        // Both borrowed from the match card, so the row in the inbox and the
        // row in the Matches tab describe the same moment with one glyph.
        NotificationAction.formalStepRequested =>
          Icons.mark_email_unread_outlined,
        NotificationAction.formalStepAccepted => Icons.check_circle_outline,
        // The glyph the journey timeline draws on an ended node.
        NotificationAction.caseEnded => Icons.close_rounded,
        NotificationAction.caseCancelled => Icons.cancel_outlined,
        NotificationAction.compatibilityCaseUpdated => Icons.handshake_rounded,
        NotificationAction.none ||
        NotificationAction.profileApproved ||
        NotificationAction.profileRejected =>
          Icons.notifications_none_rounded,
      };

  /// Profile approve/reject — both calm; rejection never wears red. Approval
  /// wears the filled `verified` badge (same glyph as the settings verified
  /// mark); rejection stays a neutral info glyph in the wine tone.
  static IconData _profileIcon(NotificationAction action) => switch (action) {
        NotificationAction.profileApproved => Icons.verified_rounded,
        NotificationAction.profileRejected => Icons.info_outline_rounded,
        _ => Icons.person_outline_rounded,
      };
}
