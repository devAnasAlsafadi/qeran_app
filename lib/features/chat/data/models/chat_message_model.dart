import '../../domain/entities/chat_message.dart';
import '../../domain/entities/message_send_status.dart';
import '../json_parsers.dart';
import 'shared_profile_model.dart';

/// Wire model for `ChatMessageDto`. Used by REST endpoints AND by
/// the SignalR `ReceiveMessage` event (backend-confirmed identical
/// shape).
class ChatMessageModel {
  final int id;
  final int conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final SharedProfileModel? sharedProfile;
  final bool isRead;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sharedProfile,
    required this.isRead,
    required this.sentAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: parseInt(json['id']),
      conversationId: parseInt(json['conversationId']),
      senderId: parseString(json['senderId']),
      senderName: parseString(json['senderName']),
      content: parseString(json['content']),
      sharedProfile: SharedProfileModel.fromJson(json['sharedProfile']),
      isRead: parseBool(json['isRead']),
      sentAt: parseNullableDateTime(json['sentAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Server messages are always `sent`. Optimistic temps live only
  /// in the cubit and never round-trip through this model.
  ChatMessage toEntity() => ChatMessage(
        serverId: id,
        clientTempId: null,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        sharedProfile: sharedProfile?.toEntity(),
        isRead: isRead,
        sentAt: sentAt,
        status: MessageSendStatus.sent,
      );
}
