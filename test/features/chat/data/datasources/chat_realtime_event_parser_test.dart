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

  group('ChatRealtimeEventParser.parseBadgeUpdate', () {
    test('valid args parse to a tab and an absolute count', () {
      final event = ChatRealtimeEventParser.parseBadgeUpdate([
        {'tab': 'likesUnread', 'count': 3},
      ]);
      expect(event, isNotNull);
      expect(event!.tab, 'likesUnread');
      expect(event.count, 3);
    });

    // The contract is to ignore keys we do not know, not to reject them. The
    // cubit stores an unknown tab where no getter reads it, so a backend that
    // grows a tab needs no client release.
    test('an unrecognised tab is passed through, not dropped', () {
      final event = ChatRealtimeEventParser.parseBadgeUpdate([
        {'tab': 'somethingNewUnread', 'count': 9},
      ]);
      expect(event, isNotNull);
      expect(event!.tab, 'somethingNewUnread');
    });

    // A tabless event names nothing to update, so it never reaches the stream.
    test('an empty or missing tab → null', () {
      expect(
        ChatRealtimeEventParser.parseBadgeUpdate([
          {'tab': '', 'count': 3},
        ]),
        isNull,
      );
      expect(
        ChatRealtimeEventParser.parseBadgeUpdate([
          {'count': 3},
        ]),
        isNull,
      );
    });

    test('count arrives as a numeric string', () {
      final event = ChatRealtimeEventParser.parseBadgeUpdate([
        {'tab': 'chatUnread', 'count': '7'},
      ]);
      expect(event, isNotNull);
      expect(event!.count, 7);
    });

    // A missing or unparseable count means zero, which clears the dot. Better
    // than leaving a stale number standing on a broadcast we could not read.
    test('a missing or unparseable count reads as zero', () {
      expect(
        ChatRealtimeEventParser.parseBadgeUpdate([
          {'tab': 'chatUnread'},
        ])!.count,
        0,
      );
      expect(
        ChatRealtimeEventParser.parseBadgeUpdate([
          {'tab': 'chatUnread', 'count': 'lots'},
        ])!.count,
        0,
      );
    });

    test('null / empty / non-map → null', () {
      expect(ChatRealtimeEventParser.parseBadgeUpdate(null), isNull);
      expect(ChatRealtimeEventParser.parseBadgeUpdate([]), isNull);
      expect(ChatRealtimeEventParser.parseBadgeUpdate([42]), isNull);
    });
  });
}
