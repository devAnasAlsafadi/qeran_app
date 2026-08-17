import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/message_type.dart';
import 'package:qeran/features/chat/data/models/chat_message_model.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';

void main() {
  group('ChatMessageModel — parsing', () {
    test('text message (sharedProfile null)', () {
      final entity = ChatMessageModel.fromJson({
        'id': 105,
        'conversationId': 42,
        'senderId': 'mm-guid',
        'senderName': 'أم محمد',
        'content': 'كيف الأحوال؟',
        'sharedProfile': null,
        'isRead': false,
        'sentAt': '2026-05-17T14:30:00Z',
      }).toEntity();

      expect(entity.serverId, 105);
      expect(entity.clientTempId, isNull);
      expect(entity.conversationId, 42);
      expect(entity.senderName, 'أم محمد');
      expect(entity.sharedProfile, isNull);
      expect(entity.isRead, isFalse);
      expect(entity.status, MessageSendStatus.sent);
      expect(entity.isSharedProfile, isFalse);
    });

    test('shared-profile message (placements ignored — always [])', () {
      final entity = ChatMessageModel.fromJson({
        'id': 104,
        'conversationId': 42,
        'senderId': 'mm-guid',
        'senderName': 'أم محمد',
        'content': '[profile:guid-x]',
        'sharedProfile': {
          'id': 'guid-x',
          'name': 'نور',
          'age': 27,
          'matchingScore': 78.5,
          'images': [
            {
              'id': 'img-1',
              'url': '/api/users/profile-images/img-1',
              'isProfile': true,
              'isBlurred': true,
            },
          ],
          'placements': [],
        },
        'isRead': true,
        'sentAt': '2026-05-17T14:20:00Z',
      }).toEntity();

      expect(entity.isSharedProfile, isTrue);
      expect(entity.sharedProfile!.id, 'guid-x');
      expect(entity.sharedProfile!.name, 'نور');
      expect(entity.sharedProfile!.age, 27);
      expect(entity.sharedProfile!.matchingScore, 78.5);
      expect(entity.sharedProfile!.images, hasLength(1));
      expect(entity.sharedProfile!.images.first.url, startsWith('http'));
      expect(entity.sharedProfile!.primaryImage!.id, 'img-1');
    });

    test('shared-profile with null age + score 0 (the hidden-chip case)',
        () {
      final entity = ChatMessageModel.fromJson({
        'id': 1,
        'conversationId': 42,
        'senderId': 'me',
        'senderName': 'Me',
        'content': '[profile:y]',
        'sharedProfile': {
          'id': 'y',
          'name': 'فاطمة',
          'age': null,
          'matchingScore': 0,
          'images': const <Map<String, dynamic>>[],
          'placements': [],
        },
        'isRead': false,
        'sentAt': '2026-05-17T14:30:00Z',
      }).toEntity();

      expect(entity.sharedProfile!.age, isNull);
      expect(entity.sharedProfile!.matchingScore, 0.0);
      expect(entity.sharedProfile!.images, isEmpty);
      expect(entity.sharedProfile!.primaryImage, isNull);
    });

    test('matchingScore arrives as int → coerces to double', () {
      final entity = ChatMessageModel.fromJson({
        'id': 1,
        'conversationId': 42,
        'senderId': 'me',
        'senderName': 'Me',
        'content': '[profile:y]',
        'sharedProfile': {
          'id': 'y',
          'name': 'فاطمة',
          'age': 25,
          'matchingScore': 78, // int instead of double
          'images': const <Map<String, dynamic>>[],
          'placements': [],
        },
        'isRead': false,
        'sentAt': '2026-05-17T14:30:00Z',
      }).toEntity();
      expect(entity.sharedProfile!.matchingScore, 78.0);
    });

    test('id/conversationId arrive as numeric strings ("105"/"42")', () {
      final entity = ChatMessageModel.fromJson({
        'id': '105',
        'conversationId': '42',
        'senderId': 'x',
        'senderName': 'X',
        'content': 'hi',
        'sharedProfile': null,
        'isRead': false,
        'sentAt': '2026-05-17T14:30:00Z',
      }).toEntity();
      expect(entity.serverId, 105);
      expect(entity.conversationId, 42);
    });

    test('missing sentAt → epoch (defensive — never crashes)', () {
      final entity = ChatMessageModel.fromJson({
        'id': 1,
        'conversationId': 42,
        'senderId': 'x',
        'senderName': 'X',
        'content': 'hi',
        'sharedProfile': null,
        'isRead': false,
      }).toEntity();
      expect(entity.sentAt.millisecondsSinceEpoch, 0);
    });
  });

  group('ChatMessageModel — the bilingual contract', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'id': 105,
          'conversationId': 42,
          'senderId': 'mm-guid',
          'senderName': 'سلمى',
          'content': 'مرحباً، أنا الخطّابة',
          'sharedProfile': null,
          'isRead': false,
          'sentAt': '2026-08-16T10:00:00Z',
          ...extra,
        };

    test('a system payload survives the trip to the entity intact', () {
      final entity = ChatMessageModel.fromJson(base({
        'type': 'System',
        'contentAr': 'مرحباً، أنا الخطّابة',
        'contentEn': 'Hello, I am your matchmaker',
      })).toEntity();

      expect(entity.type, MessageType.system);
      expect(entity.contentAr, 'مرحباً، أنا الخطّابة');
      expect(entity.contentEn, 'Hello, I am your matchmaker');
      // `content` is preserved untouched — the model resolves nothing.
      expect(entity.content, 'مرحباً، أنا الخطّابة');
      expect(entity.displayText(isArabic: false),
          'Hello, I am your matchmaker');
    });

    test('a user payload carries no pair', () {
      final entity = ChatMessageModel.fromJson(base({
        'type': 'User',
        'content': 'كيف الأحوال؟',
      })).toEntity();

      expect(entity.type, MessageType.user);
      expect(entity.contentAr, isNull);
      expect(entity.contentEn, isNull);
    });

    test('a pre-contract payload is unknown, and renders as plain text', () {
      // The 72 backfilled rows aside, any payload predating the contract has
      // no `type` at all. The model mirrors that rather than guessing.
      final entity = ChatMessageModel.fromJson(base({})).toEntity();

      expect(entity.type, MessageType.unknown);
      expect(entity.displayText(isArabic: false), 'مرحباً، أنا الخطّابة');
    });

    test('the kind is never inferred from a missing rendition', () {
      // A system message may legitimately ship one language. Reading the kind
      // off `contentEn` would demote it to a user message and lose the AR
      // rendition too.
      final entity = ChatMessageModel.fromJson(base({
        'type': 'System',
        'contentAr': 'النص العربي',
      })).toEntity();

      expect(entity.type, MessageType.system);
      expect(entity.displayText(isArabic: true), 'النص العربي');
    });

    test('a blank rendition reaches the entity as "", not null', () {
      // Deliberate: the model stays a faithful mirror of the wire and the
      // empty-vs-null equivalence is settled in `displayText`.
      final entity = ChatMessageModel.fromJson(base({
        'type': 'System',
        'contentAr': 'النص العربي',
        'contentEn': '',
      })).toEntity();

      expect(entity.contentEn, '');
      expect(entity.contentEn, isNotNull);
      expect(entity.displayText(isArabic: false), 'مرحباً، أنا الخطّابة');
    });

    test('an unrecognised future kind degrades instead of throwing', () {
      final entity = ChatMessageModel.fromJson(base({
        'type': 'Announcement',
        'contentEn': 'must not be used',
      })).toEntity();

      expect(entity.type, MessageType.unknown);
      expect(entity.displayText(isArabic: false), 'مرحباً، أنا الخطّابة');
    });
  });
}
