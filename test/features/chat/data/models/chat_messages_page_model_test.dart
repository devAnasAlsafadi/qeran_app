import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/data/models/chat_messages_page_model.dart';

void main() {
  group('ChatMessagesPageModel — parsing', () {
    test('full page — preserves newest-first order from server', () {
      final entity = ChatMessagesPageModel.fromJson({
        'data': [
          {
            'id': 105,
            'conversationId': 42,
            'senderId': 'mm',
            'senderName': 'mm',
            'content': 'newest',
            'sharedProfile': null,
            'isRead': false,
            'sentAt': '2026-05-17T14:30:00Z',
          },
          {
            'id': 104,
            'conversationId': 42,
            'senderId': 'me',
            'senderName': 'me',
            'content': 'older',
            'sharedProfile': null,
            'isRead': true,
            'sentAt': '2026-05-17T14:20:00Z',
          },
        ],
        'totalCount': 105,
        'pageNumber': 1,
        'pageSize': 20,
        'totalPages': 6,
      }).toEntity();

      expect(entity.messages, hasLength(2));
      expect(entity.messages.first.serverId, 105);
      expect(entity.totalCount, 105);
      expect(entity.pageNumber, 1);
      expect(entity.pageSize, 20);
      expect(entity.totalPages, 6);
      expect(entity.hasMore, isTrue);
    });

    test('last page → hasMore false', () {
      final entity = ChatMessagesPageModel.fromJson({
        'data': const <Map<String, dynamic>>[],
        'totalCount': 5,
        'pageNumber': 6,
        'pageSize': 20,
        'totalPages': 6,
      }).toEntity();
      expect(entity.hasMore, isFalse);
    });

    test('empty data → empty messages, page defaults safe', () {
      final entity = ChatMessagesPageModel.fromJson({}).toEntity();
      expect(entity.messages, isEmpty);
      expect(entity.totalCount, 0);
      expect(entity.pageNumber, 1);
      expect(entity.hasMore, isFalse);
    });
  });
}
