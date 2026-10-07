import 'package:equatable/equatable.dart';
import 'package:qeran/features/notifications/domain/entities/community_post_target.dart';
import 'package:qeran/features/notifications/domain/entities/notification_audience.dart';

import 'json_parsers.dart';

/// A matchmaker deep-link intent parsed from an FCM `data` payload.
///
/// Sealed so the shell's `switch` is exhaustive. The parser is pure and
/// never-throws; ids arrive as strings on the wire and are coerced.
sealed class MatchmakerDeepLink {
  const MatchmakerDeepLink();
}

/// Open a user conversation (the 4b matchmaker chat). [senderName] comes
/// from the push so the header renders immediately (no blank header).
class OpenUserChat extends MatchmakerDeepLink {
  const OpenUserChat({required this.conversationId, required this.senderName});
  final int conversationId;
  final String senderName;
}

/// Open the Cases tab (M3). [highlightCaseId] is optional / nice-to-have.
class OpenCases extends MatchmakerDeepLink {
  const OpenCases({this.highlightCaseId});
  final int? highlightCaseId;
}

/// Open a Community post at the comment or reply the notification is about
/// (C8): a new comment on her post, a report on it (D36: the post at the
/// item, never «البلاغات»), or a reply to her comment.
class OpenPost extends MatchmakerDeepLink with EquatableMixin {
  const OpenPost(this.target);
  final CommunityPostTarget target;

  @override
  List<Object?> get props => [target];
}

/// Not a matchmaker deep-link we handle → no-op.
class IgnoreDeepLink extends MatchmakerDeepLink {
  const IgnoreDeepLink();
}

/// Pure parser: FCM `data` (string-valued map) → a [MatchmakerDeepLink].
///
/// Guards (built to the real backend payloads):
///   • Cases: `action == "compatibility_case_updated"` AND
///     [NotificationAudience.isMatchmaker]. The same event is also pushed to
///     the two USERS, so the explicit `audience` field is what keeps the
///     matchmaker shell from acting on a user-targeted push. An ABSENT
///     audience fails the guard exactly as an unrecognised one does — this
///     shell acts only on what is addressed to it.
///   • Chat: `type == "chat"` with a parseable `conversationId`.
///   • Community: `screen == "community_post"` (or `type == "community"`)
///     AND [NotificationAudience.isMatchmaker], with a parseable `postId`.
///     A reply to a member's comment carries the same shape, so again the
///     audience is what keeps her shell from acting on it.
/// Anything else → [IgnoreDeepLink]. Never throws.
class MatchmakerNotificationRouter {
  const MatchmakerNotificationRouter._();

  static MatchmakerDeepLink parse(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const IgnoreDeepLink();

    final type = parseString(data['type']).toLowerCase();
    final action = parseString(data['action']).toLowerCase();
    final audience = NotificationAudience.fromWire(data['audience']);

    if (action == 'compatibility_case_updated' && audience.isMatchmaker) {
      return OpenCases(highlightCaseId: parseNullableInt(data['caseId']));
    }

    if (_isCommunity(data, type) && audience.isMatchmaker) {
      final target = CommunityPostTarget.fromData(data);
      return target == null ? const IgnoreDeepLink() : OpenPost(target);
    }

    if (type == 'chat') {
      final id = parseNullableInt(data['conversationId']);
      if (id == null) return const IgnoreDeepLink();
      return OpenUserChat(
        conversationId: id,
        senderName: parseString(data['senderName']),
      );
    }

    return const IgnoreDeepLink();
  }

  static bool _isCommunity(Map<String, dynamic> data, String type) =>
      type == 'community' ||
      parseString(data['screen']).toLowerCase() == 'community_post';
}
