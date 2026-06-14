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
        return Icons.local_offer_outlined;
      case NotificationType.profile:
        return _profileIcon(action);
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.general:
      case NotificationType.unknown:
        return Icons.notifications_none_rounded;
    }
  }

  /// Within `Match`, the glyph tells the specific story.
  static IconData _matchIcon(NotificationAction action) => switch (action) {
        NotificationAction.like => Icons.favorite_border_rounded,
        NotificationAction.likeAccepted => Icons.celebration_rounded,
        NotificationAction.photoExchangeRequested ||
        NotificationAction.photoExchangeAccepted ||
        NotificationAction.photoExchangeRejected =>
          Icons.photo_camera_outlined,
        NotificationAction.compatibilityCaseUpdated => Icons.handshake_rounded,
        _ => Icons.favorite_rounded,
      };

  /// Profile approve/reject — both calm; rejection never wears red.
  static IconData _profileIcon(NotificationAction action) => switch (action) {
        NotificationAction.profileApproved => Icons.verified_user_outlined,
        NotificationAction.profileRejected => Icons.info_outline_rounded,
        _ => Icons.person_outline_rounded,
      };
}
