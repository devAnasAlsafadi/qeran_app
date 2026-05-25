import 'package:qeran/core/api/end_points.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/conversation_type.dart';
import '../json_parsers.dart';

/// Wire model for entries in `GET /api/chat/conversations`. Future
/// list-screen will consume this; MVP UI does not.
class ConversationModel {
  final int id;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? otherParticipantImageUrl;
  final bool otherParticipantImageBlurred;
  final String type;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.id,
    required this.otherParticipantId,
    required this.otherParticipantName,
    required this.otherParticipantImageUrl,
    required this.otherParticipantImageBlurred,
    required this.type,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final image = json['otherParticipantImage'];
    String? rawImageUrl;
    bool imageBlurred = false;
    if (image is Map<String, dynamic>) {
      rawImageUrl = parseNullableString(image['url']);
      imageBlurred = parseBool(image['isBlurred']);
    }
    return ConversationModel(
      id: parseInt(json['id']),
      otherParticipantId: parseString(json['otherParticipantId']),
      otherParticipantName: parseString(json['otherParticipantName']),
      otherParticipantImageUrl: rawImageUrl,
      otherParticipantImageBlurred: imageBlurred,
      type: parseString(json['type']),
      lastMessage: parseNullableString(json['lastMessage']),
      lastMessageAt: parseNullableDateTime(json['lastMessageAt']),
      unreadCount: parseInt(json['unreadCount']),
    );
  }

  Conversation toEntity() {
    final raw = otherParticipantImageUrl;
    return Conversation(
      id: id,
      otherParticipantId: otherParticipantId,
      otherParticipantName: otherParticipantName,
      otherParticipantImageUrl:
          (raw == null || raw.isEmpty) ? null : EndPoints.absoluteUrl(raw),
      otherParticipantImageBlurred: otherParticipantImageBlurred,
      type: ConversationType.fromString(type),
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }
}
