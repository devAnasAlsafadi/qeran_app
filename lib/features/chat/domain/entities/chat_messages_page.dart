import 'package:equatable/equatable.dart';

import 'chat_message.dart';

/// One page from `GET /api/chat/conversations/{id}/messages`. The
/// `data` list arrives newest-first and we keep it that way; the UI
/// renders inside a `ListView(reverse: true)` so newest sits at the
/// visible bottom and pagination naturally fires when the user
/// scrolls toward the top (older messages).
class ChatMessagesPage extends Equatable {
  final List<ChatMessage> messages;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const ChatMessagesPage({
    required this.messages,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasMore => pageNumber < totalPages;

  @override
  List<Object?> get props =>
      [messages, totalCount, pageNumber, pageSize, totalPages];
}
