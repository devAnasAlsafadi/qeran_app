import 'package:qeran/core/enum/message_type.dart';

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

  /// Always populated by the backend, in Arabic for a system message. It is
  /// the fallback for every case the localized pair cannot serve.
  final String content;

  /// Who authored the message. Absent on payloads written before the
  /// bilingual contract, which is why it degrades to [MessageType.unknown]
  /// rather than assuming a kind.
  final MessageType type;

  /// Localized renditions, populated by the backend ONLY for a system
  /// message. Null on a user message.
  final String? contentAr;
  final String? contentEn;

  final SharedProfileModel? sharedProfile;
  final bool isRead;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.unknown,
    this.contentAr,
    this.contentEn,
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
      // Read explicitly. The kind is never inferred from an empty
      // `contentEn` — a system message may legitimately ship one language.
      type: MessageType.fromWire(parseNullableString(json['type'])),
      contentAr: parseNullableString(json['contentAr']),
      contentEn: parseNullableString(json['contentEn']),
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
        type: type,
        contentAr: contentAr,
        contentEn: contentEn,
        sharedProfile: sharedProfile?.toEntity(),
        isRead: isRead,
        sentAt: sentAt,
        status: MessageSendStatus.sent,
      );
}
