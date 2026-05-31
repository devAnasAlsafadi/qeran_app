import 'package:equatable/equatable.dart';

/// Neutral value object for the `ReceiveMessage` SignalR event, carrying
/// ONLY the fields the conversations LIST needs to update live. It
/// deliberately does NOT mirror the chat module's `ChatMessage` — the
/// matchmaker realtime layer stays free of chat-feature imports (the
/// isolation rule from 4c-1).
///
/// [contentPreview] is the raw message `content`. When it's a
/// `[profile:<guid>]` marker, the conversations row + card already render
/// the friendly shared-profile label via
/// `MatchmakerConversation.isSharedProfilePreview` — so the marker is
/// passed through unchanged here (the context-free cubit can't localize).
class ReceivedChatMessage extends Equatable {
  final int conversationId;
  final String senderId;
  final String contentPreview;
  final DateTime? sentAt;

  const ReceivedChatMessage({
    required this.conversationId,
    required this.senderId,
    required this.contentPreview,
    required this.sentAt,
  });

  @override
  List<Object?> get props => [conversationId, senderId, contentPreview, sentAt];
}
