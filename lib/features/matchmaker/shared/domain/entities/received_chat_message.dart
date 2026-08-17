import 'package:equatable/equatable.dart';
import 'package:qeran/core/enum/message_type.dart';

/// Neutral value object for the `ReceiveMessage` SignalR event, carrying
/// ONLY the fields the conversations LIST needs to update live. It
/// deliberately does NOT mirror the chat module's `ChatMessage` — the
/// matchmaker realtime layer stays free of chat-feature imports (the
/// isolation rule from 4c-1). [MessageType] is a neutral CORE wire enum,
/// not a chat-feature type, so carrying it keeps that rule intact.
///
/// [contentPreview] is the raw message `content`. When it's a
/// `[profile:<guid>]` marker, the conversations row + card already render
/// the friendly shared-profile label via
/// `MatchmakerConversation.isSharedProfilePreview` — so the marker is
/// passed through unchanged here.
///
/// The localization SIGNAL travels with it ([type] / [contentAr] /
/// [contentEn]) but is never resolved here: the cubit has no
/// `BuildContext`, and resolving at merge time would freeze the row's
/// language until the next message arrived. The card decides, at build.
class ReceivedChatMessage extends Equatable {
  final int conversationId;
  final String senderId;
  final String contentPreview;
  final DateTime? sentAt;

  /// Wire `type`. Defaults to [MessageType.user] so a payload without it
  /// previews its plain content, exactly as before this contract existed.
  final MessageType type;

  /// Localized renditions, present only on a system message.
  final String? contentAr;
  final String? contentEn;

  const ReceivedChatMessage({
    required this.conversationId,
    required this.senderId,
    required this.contentPreview,
    required this.sentAt,
    this.type = MessageType.user,
    this.contentAr,
    this.contentEn,
  });

  @override
  List<Object?> get props => [
    conversationId,
    senderId,
    contentPreview,
    sentAt,
    type,
    contentAr,
    contentEn,
  ];
}
