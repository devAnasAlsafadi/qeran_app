import 'package:equatable/equatable.dart';

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
  final String content;
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
    required this.sharedProfile,
    required this.isRead,
    required this.sentAt,
    required this.status,
  });

  bool get isSharedProfile => sharedProfile != null;

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
        sharedProfile,
        isRead,
        sentAt,
        status,
      ];
}
