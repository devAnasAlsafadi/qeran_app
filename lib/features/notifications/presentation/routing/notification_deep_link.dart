import 'package:equatable/equatable.dart';

import '../../../community/domain/entities/community_landing.dart';
import '../../domain/entities/community_post_target.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_type.dart';

/// A user-app deep-link intent parsed from a notification.
///
/// Sealed so the inbox screen's `switch` is exhaustive. The backend doc's route
/// names (`/likes/incoming`, `/chat`, …) don't exist on the user side; the real
/// targets are the Interests and Profile tabs of the home shell, and the chat
/// with the matchmaker, which is a pushed screen.
sealed class NotificationDeepLink {
  const NotificationDeepLink();
}

/// Likes tab — incoming likes, mutual matches, photo-exchange steps, and
/// formal compatibility-case updates all surface here (MVP: the tab itself; no
/// inner sub-tab selection or row highlight).
class OpenLikesTab extends NotificationDeepLink {
  const OpenLikesTab();
}

/// The user's single conversation with their matchmaker, pushed over whatever
/// is showing. The doc's `conversationId`/`senderName` are matchmaker-shaped and
/// irrelevant for the user app, which has exactly one conversation.
class OpenMatchmakerChat extends NotificationDeepLink {
  const OpenMatchmakerChat();
}

/// Profile tab — profile approved / rejected updates.
class OpenProfileTab extends NotificationDeepLink {
  const OpenProfileTab();
}

/// A Community post, pushed over whatever is showing — like the chat — at
/// the comment and reply the notification is about (H1, C8).
class OpenCommunityPost extends NotificationDeepLink with EquatableMixin {
  const OpenCommunityPost({required this.postId, this.landing});

  final int postId;

  /// Where in its discussion; none when the payload names no comment.
  final CommunityLanding? landing;

  @override
  List<Object?> get props => [postId, landing];
}

/// Community tab — never parsed from a payload: the post a notification
/// opened is gone, and «العودة إلى المجتمع» goes back to Community (Q12).
class OpenCommunityTab extends NotificationDeepLink {
  const OpenCommunityTab();
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
/// payload that omits `screen` still lands somewhere sensible. Community ids
/// arrive as strings in a push and may be numbers in the inbox: both read.
class NotificationDeepLinkRouter {
  const NotificationDeepLinkRouter._();

  static NotificationDeepLink resolve(NotificationItem item) =>
      _fromData(item.data, fallbackType: item.type);

  /// Map-based sibling of [resolve] for an FCM `RemoteMessage.data` payload
  /// (a flat map, not a [NotificationItem]). Same `screen` contract; the type
  /// fallback reads the raw `data.type` since no typed value is available.
  static NotificationDeepLink resolveData(Map<String, dynamic> data) =>
      _fromData(data, fallbackType: NotificationType.fromWire(data['type']?.toString()));

  /// Shared core: route by `data.screen`, falling back to [fallbackType] when
  /// `screen` is absent/unknown. Never throws.
  static NotificationDeepLink _fromData(
    Map<String, dynamic> data, {
    required NotificationType fallbackType,
  }) {
    final screen = (data['screen']?.toString() ?? '').toLowerCase();
    switch (screen) {
      case 'incoming_likes':
      case 'matches':
      case 'compatibility-cases':
        return const OpenLikesTab();
      case 'chat':
        return const OpenMatchmakerChat();
      case 'profile':
        return const OpenProfileTab();
      case 'community_post':
        return _communityPost(data);
    }
    return _fromType(fallbackType, data);
  }

  /// Fallback when `screen` is absent/unknown — route by notification type.
  static NotificationDeepLink _fromType(
    NotificationType type,
    Map<String, dynamic> data,
  ) => switch (type) {
        NotificationType.match => const OpenLikesTab(),
        NotificationType.chat => const OpenMatchmakerChat(),
        NotificationType.profile => const OpenProfileTab(),
        NotificationType.community => _communityPost(data),
        NotificationType.announcement ||
        NotificationType.offer ||
        NotificationType.general ||
        NotificationType.unknown =>
          const NoDeepLink(),
      };

  /// The post (contract §7.2), at `commentId` and `replyId` when they're
  /// there; nowhere without a post.
  static NotificationDeepLink _communityPost(Map<String, dynamic> data) =>
      switch (CommunityPostTarget.fromData(data)) {
        final target? => OpenCommunityPost(
          postId: target.postId,
          landing: target.landing,
        ),
        null => const NoDeepLink(),
      };
}
