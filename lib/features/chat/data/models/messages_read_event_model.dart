import '../../domain/entities/messages_read_event.dart';
import '../json_parsers.dart';

/// Wire model for the SignalR `MessagesRead` payload.
class MessagesReadEventModel {
  final int conversationId;
  final String readByUserId;
  final DateTime readAt;

  const MessagesReadEventModel({
    required this.conversationId,
    required this.readByUserId,
    required this.readAt,
  });

  factory MessagesReadEventModel.fromJson(Map<String, dynamic> json) {
    return MessagesReadEventModel(
      conversationId: parseInt(json['conversationId']),
      readByUserId: parseString(json['readByUserId']),
      readAt: parseNullableDateTime(json['readAt']) ??
          DateTime.now().toUtc(),
    );
  }

  MessagesReadEvent toEntity() => MessagesReadEvent(
        conversationId: conversationId,
        readByUserId: readByUserId,
        readAt: readAt,
      );
}
