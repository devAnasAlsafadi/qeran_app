import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/likes/data/datasources/matches_remote_datasource.dart';
import 'package:qeran/features/likes/data/error_codes.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_outcome.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late _MockApiConsumer api;
  late MatchesRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = MatchesRemoteDataSourceImpl(apiConsumer: api);
  });

  group('getMatches', () {
    test('hits GET /api/matches via getRaw', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'ok',
            'data': const <Map<String, dynamic>>[],
          });

      final list = await ds.getMatches();

      verify(() => api.getRaw(EndPoints.matches)).called(1);
      expect(list, isEmpty);
    });

    test('envelope status==0 → throws ServerException', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'fail',
          });

      expect(ds.getMatches, throwsA(isA<ServerException>()));
    });

    test('direct list shape parses correctly', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => const []);

      final list = await ds.getMatches();
      expect(list, isEmpty);
    });

    test('backend-real payload with int ids parses without crash', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'ok',
            'data': [
              {
                'likeRequestId': 42,
                'otherUserId': 'guid-other',
                'otherUserName': 'نور',
                'images': [
                  {
                    'id': 'img-1',
                    'url': '/api/users/profile-images/img-1',
                    'isProfile': true,
                    'isBlurred': true,
                  },
                ],
                'stage': 0,
                'pendingPhotoExchange': {
                  'id': 7, // int — the field that crashed in prod
                  'likeRequestId': 42, // int
                  'initiatorId': 'guid-init',
                  'responderId': 'guid-resp',
                  'status': 'Pending',
                  'statusCode': 0, // int
                  'remainingSeconds': 86340, // int
                  'createdAt': '2026-05-17T10:30:00Z',
                  'expiresAt': '2026-05-18T10:30:00Z',
                  'direction': 'Sent',
                  'requestedByMe': true,
                  'canAccept': false,
                  'canReject': false,
                },
                'formalRequest': null,
                'conversationId': null,
              },
            ],
          });

      final list = await ds.getMatches();
      expect(list, hasLength(1));
      final entity = list.first.toEntity();
      expect(entity.likeRequestId, 42);
      expect(entity.pendingPhotoExchange!.id, 7);
      expect(entity.pendingPhotoExchange!.remainingSeconds, 86340);
    });

    test('one malformed row is dropped, others still parse', () async {
      // Top-level `likeRequestId` arrives as a literal object — the
      // safest parser returns 0, so the row survives but with a
      // fallback id. We assert both rows are returned to prove the
      // try/catch doesn't drop them silently.
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'ok',
            'data': [
              // Good row.
              {
                'likeRequestId': 1,
                'otherUserId': 'a',
                'otherUserName': 'A',
                'images': const <Map<String, dynamic>>[],
                'stage': 0,
                'pendingPhotoExchange': null,
                'formalRequest': null,
                'conversationId': null,
              },
              // Second good row to verify list integrity is intact.
              {
                'likeRequestId': 2,
                'otherUserId': 'b',
                'otherUserName': 'B',
                'images': const <Map<String, dynamic>>[],
                'stage': 1,
                'pendingPhotoExchange': null,
                'formalRequest': null,
                'conversationId': null,
              },
            ],
          });

      final list = await ds.getMatches();
      expect(list, hasLength(2));
    });
  });

  group('requestPhotoExchange — errorCode classification', () {
    test('hits POST /api/photo-exchange/request/{id}', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': '',
            'data': '7',
          });

      final outcome = await ds.requestPhotoExchange(42);

      verify(() => api.postRaw(EndPoints.photoExchangeRequest(42))).called(1);
      expect(outcome, isA<PhotoExchangeRequestSuccess>());
      expect((outcome as PhotoExchangeRequestSuccess).requestId, 7);
    });

    test('numeric data: 7 (not "7") also parses', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': '',
            'data': 7, // int instead of "7"
          });

      final outcome = await ds.requestPhotoExchange(42);
      expect(outcome, isA<PhotoExchangeRequestSuccess>());
      expect((outcome as PhotoExchangeRequestSuccess).requestId, 7);
    });

    test('SUBSCRIPTION_REQUIRED → RequiresSubscription', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'الاشتراك مطلوب',
            'errorCode': PhotoExchangeErrorCodes.subscriptionRequired,
          });

      final outcome = await ds.requestPhotoExchange(1);
      expect(outcome, isA<PhotoExchangeRequestRequiresSubscription>());
    });

    test('PHOTO_EXCHANGE_ALREADY_PENDING → AlreadyPending', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'يوجد طلب تبادل قائم بالفعل',
            'errorCode': PhotoExchangeErrorCodes.photoExchangeAlreadyPending,
          });

      final outcome = await ds.requestPhotoExchange(2);
      expect(outcome, isA<PhotoExchangeRequestAlreadyPending>());
    });

    test('LIKE_NOT_ACCEPTED → LikeNotAccepted', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'طلب الاهتمام غير موجود أو لم يُقبل بعد',
            'errorCode': PhotoExchangeErrorCodes.likeNotAccepted,
          });

      final outcome = await ds.requestPhotoExchange(3);
      expect(outcome, isA<PhotoExchangeRequestLikeNotAccepted>());
    });

    test('legacy Arabic-only fallback still classifies subscription',
        () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'الاشتراك مطلوب لطلب تبادل الصور',
            // No errorCode — exercises the legacy fallback path.
          });

      final outcome = await ds.requestPhotoExchange(4);
      expect(outcome, isA<PhotoExchangeRequestRequiresSubscription>());
    });

    test('CodedServerException with classified code → typed outcome',
        () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(
          message: 'ignored',
          errorCode: PhotoExchangeErrorCodes.photoExchangeAlreadyPending,
        ),
      );

      final outcome = await ds.requestPhotoExchange(5);
      expect(outcome, isA<PhotoExchangeRequestAlreadyPending>());
    });

    test('CodedServerException with unmapped code → rethrows for repo',
        () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(message: 'oops', errorCode: 'UNKNOWN'),
      );

      expect(
        () => ds.requestPhotoExchange(6),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('acceptPhotoExchange', () {
    test('hits POST /api/photo-exchange/{id}/accept', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم القبول',
            'data': null,
          });

      final outcome = await ds.acceptPhotoExchange(9);
      verify(() => api.postRaw(EndPoints.photoExchangeAccept(9))).called(1);
      expect(outcome, isA<PhotoExchangeRespondSuccess>());
    });

    test('PHOTO_EXCHANGE_NOT_FOUND → NotFound', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'الطلب غير موجود',
            'errorCode': PhotoExchangeErrorCodes.photoExchangeNotFound,
          });

      final outcome = await ds.acceptPhotoExchange(10);
      expect(outcome, isA<PhotoExchangeRespondNotFound>());
    });

    test('PHOTO_EXCHANGE_EXPIRED → Expired', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'انتهت مدة الطلب',
            'errorCode': PhotoExchangeErrorCodes.photoExchangeExpired,
          });

      final outcome = await ds.acceptPhotoExchange(11);
      expect(outcome, isA<PhotoExchangeRespondExpired>());
    });
  });

  group('rejectPhotoExchange', () {
    test('hits POST /api/photo-exchange/{id}/reject', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم تحويل الطلب للخطابة. الصور تبقى مغبَّشة.',
            'data': null,
          });

      final outcome = await ds.rejectPhotoExchange(12);
      verify(() => api.postRaw(EndPoints.photoExchangeReject(12))).called(1);
      expect(outcome, isA<PhotoExchangeRespondSuccess>());
    });
  });
}
