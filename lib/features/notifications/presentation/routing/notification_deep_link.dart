import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_type.dart';

/// A user-app deep-link intent parsed from a notification.
///
/// Sealed so the inbox screen's `switch` is exhaustive. Every actionable
/// destination is a bottom-nav TAB inside the home shell (not a pushed route) —
/// the backend doc's route names (`/likes/incoming`, `/chat`, …) don't exist on
/// the user side; the real targets are the Likes / Messages / Profile tabs.
sealed class NotificationDeepLink {
  const NotificationDeepLink();
}

/// Likes tab — incoming likes, mutual matches, photo-exchange steps, and
/// formal compatibility-case updates all surface here (MVP: the tab itself; no
/// inner sub-tab selection or row highlight).
class OpenLikesTab extends NotificationDeepLink {
  const OpenLikesTab();
}

/// Messages tab — the user's single conversation with their matchmaker. The
/// doc's `conversationId`/`senderName` are matchmaker-shaped and irrelevant for
/// the user app, which has exactly one conversation.
class OpenMessagesTab extends NotificationDeepLink {
  const OpenMessagesTab();
}

/// Profile tab — profile approved / rejected updates.
class OpenProfileTab extends NotificationDeepLink {
  const OpenProfileTab();
}

/// No actionable destination (General / Announcement / Offer, or an unknown
/// screen) — tapping the row does nothing; the user stays on the inbox.
class NoDeepLink extends NotificationDeepLink {
  const NoDeepLink();
}

/// Pure parser: a [NotificationItem] → a [NotificationDeepLink]. Never throws.
///
/// `data.screen` drives routing (the documented contract). When `screen` is
/// missing or unrecognised, it falls back to the typed [NotificationType] so a
/// payload that omits `screen` still lands somewhere sensible.
class NotificationDeepLinkRouter {
  const NotificationDeepLinkRouter._();

  static NotificationDeepLink resolve(NotificationItem item) {
    final screen = (item.data['screen']?.toString() ?? '').toLowerCase();
    switch (screen) {
      case 'incoming_likes':
      case 'matches':
      case 'compatibility-cases':
        return const OpenLikesTab();
      case 'chat':
        return const OpenMessagesTab();
      case 'profile':
        return const OpenProfileTab();
    }
    return _fromType(item.type);
  }

  /// Fallback when `screen` is absent/unknown — route by notification type.
  static NotificationDeepLink _fromType(NotificationType type) => switch (type) {
        NotificationType.match => const OpenLikesTab(),
        NotificationType.chat => const OpenMessagesTab(),
        NotificationType.profile => const OpenProfileTab(),
        NotificationType.announcement ||
        NotificationType.offer ||
        NotificationType.general ||
        NotificationType.unknown =>
          const NoDeepLink(),
      };
}
