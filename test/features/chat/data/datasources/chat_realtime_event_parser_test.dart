import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/data/datasources/chat_realtime_event_parser.dart';

void main() {
  group('parseReceiveMessage', () {
    test('valid ChatMessageDto-shaped payload → ChatMessage entity', () {
      final entity = ChatRealtimeEventParser.parseReceiveMessage([
        {
          'id': 200,
          'conversationId': 42,
          'senderId': 'mm',
          'senderName': 'أم محمد',
          'content': 'hello',
          'sharedProfile': null,
          'isRead': false,
          'sentAt': '2026-05-21T10:30:00Z',
        },
      ]);
      expect(entity, isNotNull);
      expect(entity!.serverId, 200);
      expect(entity.conversationId, 42);
      expect(entity.senderId, 'mm');
      expect(entity.content, 'hello');
      expect(entity.isRead, isFalse);
    });

    test('Map<dynamic, dynamic> still parses (normalised to typed map)',
        () {
      final dynamicMap = <dynamic, dynamic>{
        'id': 1,
        'conversationId': 42,
        'senderId': 'me',
        'senderName': 'me',
        'content': 'x',
        'sharedProfile': null,
        'isRead': true,
        'sentAt': '2026-05-21T10:30:00Z',
      };
      final entity = ChatRealtimeEventParser.parseReceiveMessage([dynamicMap]);
      expect(entity, isNotNull);
      expect(entity!.serverId, 1);
    });

    test('null args → null (no throw)', () {
      expect(ChatRealtimeEventParser.parseReceiveMessage(null), isNull);
    });

    test('empty args → null', () {
      expect(ChatRealtimeEventParser.parseReceiveMessage([]), isNull);
    });

    test('non-map arg → null', () {
      expect(
          ChatRealtimeEventParser.parseReceiveMessage(['oops']), isNull);
    });

    test('shared-profile payload parses (placements ignored, always [])',
        () {
      final entity = ChatRealtimeEventParser.parseReceiveMessage([
        {
          'id': 300,
          'conversationId': 42,
          'senderId': 'mm',
          'senderName': 'mm',
          'content': '[profile:guid-x]',
          'sharedProfile': {
            'id': 'guid-x',
            'name': 'نور',
            'age': 27,
            'matchingScore': 78.5,
            'images': const <Map<String, dynamic>>[],
            'placements': const <Map<String, dynamic>>[],
          },
          'isRead': false,
          'sentAt': '2026-05-21T10:30:00Z',
        },
      ]);
      expect(entity, isNotNull);
      expect(entity!.isSharedProfile, isTrue);
      expect(entity.sharedProfile!.name, 'نور');
    });
  });

  group('parseMessagesRead', () {
    test('valid MessagesRead payload → entity', () {
      final entity = ChatRealtimeEventParser.parseMessagesRead([
        {
          'conversationId': 42,
          'readByUserId': 'mm-guid',
          'readAt': '2026-05-21T10:30:00Z',
        },
      ]);
      expect(entity, isNotNull);
      expect(entity!.conversationId, 42);
      expect(entity.readByUserId, 'mm-guid');
      expect(entity.readAt.year, 2026);
    });

    test('conversationId arrives as numeric string', () {
      final entity = ChatRealtimeEventParser.parseMessagesRead([
        {
          'conversationId': '42',
          'readByUserId': 'mm-guid',
          'readAt': '2026-05-21T10:30:00Z',
        },
      ]);
      expect(entity, isNotNull);
      expect(entity!.conversationId, 42);
    });

    test('null / empty / non-map → null', () {
      expect(ChatRealtimeEventParser.parseMessagesRead(null), isNull);
      expect(ChatRealtimeEventParser.parseMessagesRead([]), isNull);
      expect(ChatRealtimeEventParser.parseMessagesRead([42]), isNull);
    });
  });
}
