import 'package:qeran/core/enum/message_type.dart';

import '../../domain/entities/received_chat_message.dart';
import '../json_parsers.dart';

/// Maps the `ReceiveMessage` wire payload (the full ChatMessageDto) to the
/// list-only [ReceivedChatMessage] VO. Only the fields the conversations
/// list needs are read (`conversationId`, `senderId`, `content`, `sentAt`);
/// the rest of the DTO is ignored. Tolerant parsing via shared
/// `json_parsers`; the event parser wrapping this guarantees never-throw /
/// null-on-malformed at the dispatch site.
class ReceivedChatMessageModel {
  const ReceivedChatMessageModel._();

  static ReceivedChatMessage fromJson(Map<String, dynamic> json) {
    return ReceivedChatMessage(
      conversationId: parseInt(json['conversationId']),
      senderId: parseString(json['senderId']),
      contentPreview: parseString(json['content']),
      sentAt: parseNullableDateTime(json['sentAt']),
      // Carried, not resolved — the card localizes at build time.
      type: MessageType.fromWire(parseNullableString(json['type'])),
      contentAr: parseNullableString(json['contentAr']),
      contentEn: parseNullableString(json['contentEn']),
    );
  }
}
