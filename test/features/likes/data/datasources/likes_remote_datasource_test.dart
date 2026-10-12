import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/likes/data/datasources/likes_remote_datasource.dart';
import 'package:qeran/features/likes/data/error_codes.dart';
import 'package:qeran/features/likes/domain/entities/like_action_outcome.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late _MockApiConsumer api;
  late LikesRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = LikesRemoteDataSourceImpl(apiConsumer: api);
  });

  group('acceptLike', () {
    test('hits POST /api/likes/{id}/accept with no body', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم القبول',
            'data': null,
          });

      final outcome = await ds.acceptLike(42);

      verify(() => api.postRaw(EndPoints.likesAccept(42))).called(1);
      expect(outcome, isA<LikeActionSuccess>());
    });

    test('status 1 envelope → LikeActionSuccess with server message', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم القبول',
            'data': null,
          });

      final outcome = await ds.acceptLike(1) as LikeActionSuccess;

      expect(outcome.serverMessage, 'تم القبول');
    });

    // R12: Tariq confirmed every refusal carries a code. Without one, its
    // words are never read — the old fallbacks' sentences and his new ones.
    for (final sentence in const [
      'الاشتراك مطلوب لقبول الاهتمام',
      'انتهى رصيد الاهتمام في تجربتك المجانية، اشترك للمزيد',
      'انتهت مدة الطلب',
      'الطلب غير موجود أو منتهي',
    ]) {
      test('an uncoded refusal is a plain failure: "$sentence"', () async {
        when(() => api.postRaw(any())).thenAnswer((_) async => {
              'status': 0,
              'message': sentence,
              'data': null,
            });

        final outcome = await ds.acceptLike(2);

        expect(outcome, isA<LikeActionFailure>());
      });
    }

    test('unknown status 0 message → LikeActionFailure (no throw)', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'some unmapped server error',
            'data': null,
          });

      final outcome = await ds.acceptLike(5);

      expect(outcome, isA<LikeActionFailure>());
    });

    test('postRaw throws unmapped ServerException → rethrows for repo',
        () async {
      when(() => api.postRaw(any()))
          .thenThrow(ServerException(message: 'Operation Failed'));

      expect(() => ds.acceptLike(6), throwsA(isA<ServerException>()));
    });

    test('an uncoded throw is never read: rethrown, the generic error',
        () async {
      when(() => api.postRaw(any())).thenThrow(
          ServerException(message: 'الاشتراك مطلوب لقبول الاهتمام'));

      expect(() => ds.acceptLike(7), throwsA(isA<ServerException>()));
    });
  });

  group('rejectLike', () {
    test('hits POST /api/likes/{id}/reject', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم الرفض',
            'data': null,
          });

      final outcome = await ds.rejectLike(9);

      verify(() => api.postRaw(EndPoints.likesReject(9))).called(1);
      expect(outcome, isA<LikeActionSuccess>());
    });

    test('an uncoded refusal to decline is a plain failure', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'الطلب غير موجود',
            'data': null,
          });

      final outcome = await ds.rejectLike(10);

      expect(outcome, isA<LikeActionFailure>());
    });
  });

  group('classifier — errorCode-first', () {
    test('SUBSCRIPTION_REQUIRED errorCode → RequiresSubscription '
        '(message irrelevant)', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'some garbage non-Arabic message',
            'errorCode': LikesErrorCodes.subscriptionRequired,
            'data': null,
          });

      final outcome = await ds.acceptLike(100);
      expect(outcome, isA<LikeActionRequiresSubscription>());
    });

    test('LIKE_EXPIRED errorCode → Expired', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'whatever',
            'errorCode': LikesErrorCodes.likeExpired,
            'data': null,
          });

      final outcome = await ds.acceptLike(101);
      expect(outcome, isA<LikeActionExpired>());
    });

    test('LIKE_NOT_FOUND errorCode → NotFoundOrExpired', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'whatever',
            'errorCode': LikesErrorCodes.likeNotFound,
            'data': null,
          });

      final outcome = await ds.acceptLike(102);
      expect(outcome, isA<LikeActionNotFoundOrExpired>());
    });

    test('CodedServerException with SUBSCRIPTION_REQUIRED → typed outcome',
        () async {
      when(() => api.postRaw(any())).thenThrow(
        CodedServerException(
          message: 'ignored-arabic-or-not',
          errorCode: LikesErrorCodes.subscriptionRequired,
        ),
      );

      final outcome = await ds.acceptLike(103);
      expect(outcome, isA<LikeActionRequiresSubscription>());
    });
  });
}
