import 'package:equatable/equatable.dart';

/// A matchmaker ↔ user conversation row from
/// `GET /api/matchmaker/conversations/users`. [profileImageUrl] is already
/// absolute (the data layer runs the server's relative path through
/// `EndPoints.absoluteUrl`); `null` when the user has no profile image.
///
/// [lastMessagePreview] may be a shared-profile marker of the form
/// `[profile:<guid>]` rather than text — surfaced via [isSharedProfilePreview]
/// so the UI can render a friendly label instead of the raw marker.
class MatchmakerConversation extends Equatable {
  final String userId;
  final String fullName;
  final String? profileImageUrl;
  final int conversationId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;

  const MatchmakerConversation({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.conversationId,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
  });

  /// True when the last message is a shared-profile marker, not plain text.
  bool get isSharedProfilePreview =>
      lastMessagePreview?.startsWith('[profile:') ?? false;

  /// Minimal additive copy — only the fields a live `ReceiveMessage`
  /// updates (preview / timestamp / unread). All others carry through.
  MatchmakerConversation copyWith({
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    int? unreadCount,
  }) {
    return MatchmakerConversation(
      userId: userId,
      fullName: fullName,
      profileImageUrl: profileImageUrl,
      conversationId: conversationId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        profileImageUrl,
        conversationId,
        lastMessageAt,
        lastMessagePreview,
        unreadCount,
      ];
}
