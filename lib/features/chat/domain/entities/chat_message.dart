import 'package:equatable/equatable.dart';
import 'package:qeran/core/enum/message_type.dart';

import 'message_send_status.dart';
import 'shared_profile.dart';

/// One message in a chat.
///
/// Either a plain text message (`sharedProfile == null`) or a
/// profile-share message (`sharedProfile != null`). The raw
/// `[profile:guid]` content placeholder is NEVER rendered — the UI
/// inspects `sharedProfile` and renders the dedicated card widget.
///
/// `serverId` is null only for optimistic outgoing temps. Real server
/// messages always have one. `clientTempId` is the inverse — set only
/// while we hold an optimistic temp, cleared once the server id arrives.
class ChatMessage extends Equatable {
  /// Server-assigned id. `null` only while an optimistic temp is
  /// in-flight before REST returns.
  final int? serverId;

  /// Client-side uuid for optimistic temps. `null` for any message
  /// that originated server-side.
  final String? clientTempId;

  final int conversationId;
  final String senderId;
  final String senderName;

  /// The message as the backend always sends it — Arabic for a system
  /// message. Every path that cannot use the localized pair lands here, so
  /// it is never empty in practice.
  final String content;

  /// Who authored the message. Defaults to [MessageType.user] because the
  /// only entity built by hand is the optimistic outgoing temp, which the
  /// user did author; server rows carry the wire value.
  final MessageType type;

  /// Localized renditions, present only on a system message.
  final String? contentAr;
  final String? contentEn;

  final SharedProfile? sharedProfile;
  final bool isRead;
  final DateTime sentAt;

  /// Local lifecycle status — `sent` for any server-originated row.
  final MessageSendStatus status;

  const ChatMessage({
    required this.serverId,
    required this.clientTempId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.user,
    this.contentAr,
    this.contentEn,
    required this.sharedProfile,
    required this.isRead,
    required this.sentAt,
    required this.status,
  });

  bool get isSharedProfile => sharedProfile != null;

  /// The text to render, for the locale the caller is currently in.
  ///
  /// Only an explicit system message consults the localized pair; anything
  /// else — a user message, or a payload with no `type` at all — uses
  /// [content]. A localized field that is missing OR blank falls back to
  /// [content] too: `parseNullableString` keeps `""` as an empty string
  /// rather than nulling it, so both have to read as "not usable here".
  ///
  /// There is deliberately no attempt at the opposite language. [content]
  /// is always populated, which makes it the one honest fallback.
  ///
  /// Callers must resolve this inside `build` (from `context.locale`) so a
  /// language switch re-renders the text without a refetch.
  String displayText({required bool isArabic}) {
    if (!type.usesLocalizedContent) return content;
    final localized = isArabic ? contentAr : contentEn;
    if (localized == null || localized.isEmpty) return content;
    return localized;
  }

  ChatMessage copyWith({
    int? serverId,
    String? clientTempId,
    bool? isRead,
    DateTime? sentAt,
    MessageSendStatus? status,
  }) {
    return ChatMessage(
      serverId: serverId ?? this.serverId,
      clientTempId: clientTempId ?? this.clientTempId,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      // Carried explicitly: this constructor names every field, so an
      // omission here would silently reset a system message to its
      // defaults on the first optimistic-temp reconciliation.
      type: type,
      contentAr: contentAr,
      contentEn: contentEn,
      sharedProfile: sharedProfile,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        serverId,
        clientTempId,
        conversationId,
        senderId,
        senderName,
        content,
        type,
        contentAr,
        contentEn,
        sharedProfile,
        isRead,
        sentAt,
        status,
      ];
}
