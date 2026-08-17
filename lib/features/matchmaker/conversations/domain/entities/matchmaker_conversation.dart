import 'package:equatable/equatable.dart';
import 'package:qeran/core/enum/message_type.dart';

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

  /// Localization signal for the last message, populated ONLY by the live
  /// `ReceiveMessage` path. REST rows leave these at their defaults, so a
  /// cold-loaded row previews the server-rendered [lastMessagePreview] in
  /// whatever language the backend chose — see [previewText].
  final MessageType lastMessageType;
  final String? lastMessageContentAr;
  final String? lastMessageContentEn;

  const MatchmakerConversation({
    required this.userId,
    required this.fullName,
    required this.profileImageUrl,
    required this.conversationId,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadCount,
    this.lastMessageType = MessageType.user,
    this.lastMessageContentAr,
    this.lastMessageContentEn,
  });

  /// True when the last message is a shared-profile marker, not plain text.
  bool get isSharedProfilePreview =>
      lastMessagePreview?.startsWith('[profile:') ?? false;

  /// The preview text for the locale the caller is currently in.
  ///
  /// Mirrors `ChatMessage.displayText`: only an explicit system message
  /// consults the localized pair, and a missing OR blank field falls through
  /// to [lastMessagePreview]. For a REST-loaded row that fallback IS the
  /// answer — the server rendered it and the client cannot re-language it.
  ///
  /// Must be called inside `build` (from `context.locale`) so switching
  /// language repaints the row.
  String previewText({required bool isArabic}) {
    final fallback = lastMessagePreview ?? '';
    if (!lastMessageType.usesLocalizedContent) return fallback;
    final localized = isArabic ? lastMessageContentAr : lastMessageContentEn;
    if (localized == null || localized.isEmpty) return fallback;
    return localized;
  }

  /// Minimal additive copy — only the fields a live `ReceiveMessage`
  /// updates (preview / timestamp / unread). All others carry through,
  /// INCLUDING the localization tuple: use [withLastMessage] to replace it.
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
      lastMessageType: lastMessageType,
      lastMessageContentAr: lastMessageContentAr,
      lastMessageContentEn: lastMessageContentEn,
    );
  }

  /// Replaces the whole "last message" tuple from a live `ReceiveMessage`.
  ///
  /// The three localization fields move TOGETHER and always overwrite. A
  /// per-field `??` carry-over would let a stale English rendition survive a
  /// newer system message that shipped only Arabic, and the EN reader would
  /// keep seeing the previous message's text.
  MatchmakerConversation withLastMessage({
    required String? preview,
    required DateTime? at,
    required int unreadCount,
    required MessageType type,
    required String? contentAr,
    required String? contentEn,
  }) {
    return MatchmakerConversation(
      userId: userId,
      fullName: fullName,
      profileImageUrl: profileImageUrl,
      conversationId: conversationId,
      lastMessageAt: at ?? lastMessageAt,
      lastMessagePreview: preview ?? lastMessagePreview,
      unreadCount: unreadCount,
      lastMessageType: type,
      lastMessageContentAr: contentAr,
      lastMessageContentEn: contentEn,
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
        lastMessageType,
        lastMessageContentAr,
        lastMessageContentEn,
      ];
}
