import '../../domain/entities/chat_messages_page.dart';
import '../json_parsers.dart';
import 'chat_message_model.dart';

/// Wire model for the paged messages response. The server's outer
/// envelope (`status/message/errorCode/data`) is peeled by the
/// datasource; what we parse here is the inner `PagedResult` shape.
class ChatMessagesPageModel {
  final List<ChatMessageModel> messages;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const ChatMessagesPageModel({
    required this.messages,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory ChatMessagesPageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessagesPageModel(
      messages: _parseList(json['data']),
      totalCount: parseInt(json['totalCount']),
      pageNumber: parseInt(json['pageNumber'], fallback: 1),
      pageSize: parseInt(json['pageSize']),
      totalPages: parseInt(json['totalPages']),
    );
  }

  static List<ChatMessageModel> _parseList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList(growable: false);
  }

  ChatMessagesPage toEntity() => ChatMessagesPage(
        messages: messages.map((m) => m.toEntity()).toList(growable: false),
        totalCount: totalCount,
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalPages: totalPages,
      );
}
