import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/match_card_model.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';

void main() {
  group('MatchCardModel — stage parsing', () {
    test('stage 0 parses → waitingForPhotoExchange', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 42,
        'otherUserId': 'guid',
        'otherUserName': 'نور',
        'images': const <Map<String, dynamic>>[],
        'stage': 0,
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      expect(entity.likeRequestId, 42);
      expect(entity.stage, MatchStage.waitingForPhotoExchange);
      expect(entity.pendingPhotoExchange, isNull);
      expect(entity.formalRequest, isNull);
      expect(entity.conversationId, isNull);
    });

    test('stage 1 parses → photosExchanged with formalRequest', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'guid',
        'otherUserName': 'نور',
        'images': const <Map<String, dynamic>>[],
        'stage': 1,
        'pendingPhotoExchange': null,
        'formalRequest': {
          'id': 7,
          'maleUserId': 'm',
          'maleUserName': 'محمد',
          'femaleUserId': 'f',
          'femaleUserName': 'نور',
          'status': 'WaitingForParentAppointment',
          'statusNameAr': 'طلب موعد مع الأهل',
          'statusNameEn': 'Waiting for parent appointment',
          'updatedByMatchmakerAt': '2026-05-18T14:20:00Z',
          'createdAt': '2026-05-17T10:30:00Z',
        },
        'conversationId': null,
      }).toEntity();

      expect(entity.stage, MatchStage.photosExchanged);
      expect(entity.formalRequest, isNotNull);
      expect(entity.formalRequest!.localizedStatusName('ar'),
          'طلب موعد مع الأهل');
      expect(entity.formalRequest!.localizedStatusName('en'),
          'Waiting for parent appointment');
      expect(entity.formalRequest!.updatedByMatchmakerAt, isNotNull);
    });

    test('stage 2 parses with conversationId', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'guid',
        'otherUserName': 'نور',
        'images': const <Map<String, dynamic>>[],
        'stage': 2,
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': 'conv-123',
      }).toEntity();

      expect(entity.stage, MatchStage.matchmakerEngaged);
      expect(entity.conversationId, 'conv-123');
    });

    test('unknown stage value → MatchStage.unknown', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'guid',
        'otherUserName': 'نور',
        'images': const <Map<String, dynamic>>[],
        'stage': 99,
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      expect(entity.stage, MatchStage.unknown);
    });
  });

  group('MatchCardModel — images', () {
    test('parses isProfile and isBlurred per item; URL resolved to absolute',
        () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 1,
        'images': [
          {
            'id': 'img-1',
            'url': '/api/users/profile-images/img-1',
            'isProfile': true,
            'isBlurred': false,
          },
          {
            'id': 'img-2',
            'url': '/api/users/profile-images/img-2',
            'isProfile': false,
            'isBlurred': false,
          },
        ],
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      expect(entity.images, hasLength(2));
      expect(entity.images.first.isProfile, isTrue);
      expect(entity.images.first.url, startsWith('http'));
      expect(entity.primaryImage, isNotNull);
      expect(entity.primaryImage!.id, 'img-1');
    });

    test('missing images list → empty', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
      }).toEntity();
      expect(entity.images, isEmpty);
      expect(entity.primaryImage, isNull);
    });
  });

  group('MatchCardModel — pendingPhotoExchange', () {
    test('full populated payload parses', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': 7,
          'likeRequestId': 42,
          'initiatorId': 'me',
          'responderId': 'them',
          'status': 'Pending',
          'statusCode': 0,
          'remainingSeconds': 86340,
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-18T10:30:00Z',
          'direction': 'Sent',
          'requestedByMe': true,
          'canAccept': false,
          'canReject': false,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      final p = entity.pendingPhotoExchange!;
      expect(p.id, 7);
      expect(p.likeRequestId, 42);
      expect(p.status, PhotoExchangeStatus.pending);
      expect(p.direction, PhotoExchangeDirection.sent);
      expect(p.requestedByMe, isTrue);
      expect(p.remainingSeconds, 86340);
    });

    test('Received + canAccept/canReject parses to responder shape', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': 9,
          'likeRequestId': 42,
          'initiatorId': 'them',
          'responderId': 'me',
          'status': 'Pending',
          'statusCode': 0,
          'remainingSeconds': 3600,
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-17T14:30:00Z',
          'direction': 'Received',
          'requestedByMe': false,
          'canAccept': true,
          'canReject': true,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      final p = entity.pendingPhotoExchange!;
      expect(p.direction, PhotoExchangeDirection.received);
      expect(p.canAccept, isTrue);
      expect(p.canReject, isTrue);
    });

    test('non-Map pendingPhotoExchange → null (defensive)', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': 'not-a-map',
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();
      expect(entity.pendingPhotoExchange, isNull);
    });

    test('missing remainingSeconds parses as null', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': 1,
          'likeRequestId': 1,
          'initiatorId': 'me',
          'responderId': 'them',
          'status': 'Pending',
          'statusCode': 0,
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-18T10:30:00Z',
          'direction': 'Sent',
          'requestedByMe': true,
          'canAccept': false,
          'canReject': false,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();
      expect(entity.pendingPhotoExchange!.remainingSeconds, isNull);
    });
  });

  group('Type-drift resilience — int↔String', () {
    test('backend-real shape: all numeric ids parse from int (no crash)', () {
      // This is the exact failing wire shape reported from prod:
      // `pendingPhotoExchange.id`, `likeRequestId`, `statusCode`, and
      // `remainingSeconds` arrive as int. Old casts crashed with
      // `int is not String?`; safe parsers absorb them.
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 42,
        'otherUserId': 'guid-other',
        'otherUserName': 'نور',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': 7,
          'likeRequestId': 42,
          'initiatorId': 'guid-init',
          'responderId': 'guid-resp',
          'status': 'Pending',
          'statusCode': 0,
          'remainingSeconds': 86340,
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-18T10:30:00Z',
          'direction': 'Sent',
          'requestedByMe': true,
          'canAccept': false,
          'canReject': false,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      final p = entity.pendingPhotoExchange!;
      expect(p.id, 7);
      expect(p.likeRequestId, 42);
      expect(p.statusCode, 0);
      expect(p.remainingSeconds, 86340);
    });

    test('numeric ids accepted as strings too ("7" / "42")', () {
      // Defensive — backend may send the same fields stringified in
      // some payloads (e.g. data: "7" from the request endpoint).
      final entity = MatchCardModel.fromJson({
        'likeRequestId': '42',
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': '0',
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': '7',
          'likeRequestId': '42',
          'initiatorId': 'i',
          'responderId': 'r',
          'status': 'Pending',
          'statusCode': '0',
          'remainingSeconds': '60',
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-18T10:30:00Z',
          'direction': 'Sent',
          'requestedByMe': true,
          'canAccept': false,
          'canReject': false,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      expect(entity.likeRequestId, 42);
      expect(entity.pendingPhotoExchange!.id, 7);
      expect(entity.pendingPhotoExchange!.remainingSeconds, 60);
    });

    test('status / direction arriving as int does NOT crash the string '
        'field', () {
      // Backend has been observed flipping these between enum string
      // and enum int. The model stringifies via the safe parser so a
      // single drifted field never blanks the matches list.
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': {
          'id': 1,
          'likeRequestId': 1,
          'initiatorId': 'i',
          'responderId': 'r',
          'status': 0, // ← int, not "Pending"
          'statusCode': 0,
          'remainingSeconds': null,
          'createdAt': '2026-05-17T10:30:00Z',
          'expiresAt': '2026-05-18T10:30:00Z',
          'direction': 1, // ← int, not "Received"
          'requestedByMe': false,
          'canAccept': true,
          'canReject': true,
        },
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      final p = entity.pendingPhotoExchange!;
      expect(p.statusCode, 0);
      expect(p.canAccept, isTrue);
      expect(p.canReject, isTrue);
      // status/direction store the stringified value; the entity
      // converts statusCode → enum, direction string → enum.
    });

    test('formalRequest with int id and string status parses cleanly', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 1,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': null,
        'formalRequest': {
          'id': 7, // int
          'maleUserId': 'm',
          'maleUserName': 'محمد',
          'femaleUserId': 'f',
          'femaleUserName': 'نور',
          'status': 'WaitingForParentAppointment',
          'statusNameAr': 'طلب موعد مع الأهل',
          'statusNameEn': 'Waiting for parent appointment',
          'updatedByMatchmakerAt': '2026-05-18T14:20:00Z',
          'createdAt': '2026-05-17T10:30:00Z',
        },
        'conversationId': null,
      }).toEntity();

      expect(entity.formalRequest!.id, 7);
      expect(entity.formalRequest!.statusNameAr, 'طلب موعد مع الأهل');
    });

    test('conversationId arriving as int is stringified safely', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 2,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': 12345, // int instead of string
      }).toEntity();

      expect(entity.conversationId, '12345');
    });

    test('image id as int parses without crash', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 1,
        'images': [
          {
            'id': 9, // int
            'url': '/api/users/profile-images/img-9',
            'isProfile': true,
            'isBlurred': false,
          },
        ],
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();

      expect(entity.images, hasLength(1));
      expect(entity.images.first.id, '9');
    });

    test('isBlurred missing defaults to true (privacy-safe)', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 0,
        'images': [
          {
            'id': 'img-1',
            'url': '/api/users/profile-images/img-1',
            'isProfile': true,
            // isBlurred intentionally missing
          },
        ],
        'pendingPhotoExchange': null,
        'formalRequest': null,
        'conversationId': null,
      }).toEntity();
      expect(entity.images.first.isBlurred, isTrue);
    });
  });

  group('FormalRequest — defensive', () {
    test('non-Map formalRequest → null', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 1,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': null,
        'formalRequest': 42,
        'conversationId': null,
      }).toEntity();
      expect(entity.formalRequest, isNull);
    });

    test('empty status names → localizedStatusName falls back to ""', () {
      final entity = MatchCardModel.fromJson({
        'likeRequestId': 1,
        'otherUserId': 'g',
        'otherUserName': 'n',
        'stage': 1,
        'images': const <Map<String, dynamic>>[],
        'pendingPhotoExchange': null,
        'formalRequest': {
          'id': 1,
          'maleUserId': 'm',
          'maleUserName': '',
          'femaleUserId': 'f',
          'femaleUserName': '',
          'status': 'X',
          'statusNameAr': '',
          'statusNameEn': '',
          'createdAt': '2026-05-17T10:30:00Z',
        },
        'conversationId': null,
      }).toEntity();
      expect(entity.formalRequest, isNotNull);
      expect(entity.formalRequest!.localizedStatusName('ar'), '');
      expect(entity.formalRequest!.localizedStatusName('en'), '');
    });
  });
}
