import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:qeran/features/discovery/domain/entities/like_outcome.dart';
import 'package:qeran/features/likes/data/error_codes.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

/// Minimal `data` envelope so `DiscoveryPageModel.fromJson` doesn't bail.
Map<String, dynamic> _emptyPage() => {
  'status': 1,
  'message': 'ok',
  'data': {
    'data': const [],
    'pageNumber': 1,
    'pageSize': 10,
    'totalCount': 0,
    'totalPages': 0,
  },
};

void main() {
  late _MockApiConsumer api;
  late DiscoveryRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = DiscoveryRemoteDataSourceImpl(apiConsumer: api);
  });

  group('fetchPage — POST Discovery/search (run 11)', () {
    Map<String, dynamic> sentBody() {
      final captured = verify(
        () => api.postRaw(captureAny(), body: captureAny(named: 'body')),
      ).captured;
      expect(captured.first, 'Discovery/search');
      return captured.last as Map<String, dynamic>;
    }

    setUp(
      () => when(
        () => api.postRaw(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => _emptyPage()),
    );

    test('the filters go in the body, by question id; ranges as numbers', () async {
      await ds.fetchPage(
        page: 1,
        pageSize: 20,
        filterParams: const {
          'RangeFrom[1]': '18',
          'RangeTo[1]': '50',
          'RangeFrom[5]': '160.5',
          'QuestionFilters[18]': 'Single',
          'QuestionFilters[22]': 'Honest,Ambitious,FamilyOriented',
        },
      );

      final body = sentBody();
      expect(body, {
        'page': 1,
        'pageSize': 20,
        'questionFilters': {
          '18': 'Single',
          '22': 'Honest,Ambitious,FamilyOriented',
        },
        'rangeFrom': {'1': 18, '5': 160.5},
        'rangeTo': {'1': 50},
      });
      expect(
        (body['rangeFrom'] as Map)['1'],
        isA<int>(),
        reason: 'a whole edge is 18, not 18.0',
      );
      verifyNever(
        () => api.getRaw(any(), queryParameters: any(named: 'queryParameters')),
      );
    });

    test('no filters, or empty ones: page and pageSize only', () async {
      await ds.fetchPage();
      expect(sentBody(), {'page': 1, 'pageSize': 10});

      await ds.fetchPage(page: 2, filterParams: const {});
      expect(sentBody(), {'page': 2, 'pageSize': 10});
    });

    test('a key it does not know, or a range that is not a number, is '
        'left out', () async {
      await ds.fetchPage(
        filterParams: const {'Other[3]': 'x', 'RangeTo[5]': 'tall'},
      );

      expect(sentBody(), {'page': 1, 'pageSize': 10});
    });
  });

  group('fetchPage — daily views cap', () {
    Future<Object?> fetchError() =>
        ds.fetchPage().then<Object?>((_) => null, onError: (e) => e);

    test('200 {status:0, DAILY_VIEWS_EXCEEDED, data.resetAt} → typed '
        'exception carrying the parsed resetAt', () async {
      when(
        () => api.postRaw(any(), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => {
          'status': 0,
          'errorCode': DiscoveryErrorCodes.dailyViewsExceeded,
          'message': 'capped',
          'data': {'resetAt': '2026-07-18T00:00:00Z'},
        },
      );

      final err = await fetchError();
      expect(err, isA<DailyViewsExceededException>());
      expect(
        (err as DailyViewsExceededException).resetAt.toUtc(),
        DateTime.utc(2026, 7, 18),
      );
    });

    test('non-2xx thrown CodedServerException with the code → typed '
        'exception (fallback resetAt = next UTC midnight)', () async {
      when(
        () => api.postRaw(any(), body: any(named: 'body')),
      ).thenThrow(
        CodedServerException(
          message: 'capped',
          errorCode: DiscoveryErrorCodes.dailyViewsExceeded,
        ),
      );

      final err = await fetchError();
      expect(err, isA<DailyViewsExceededException>());
      final resetAt = (err as DailyViewsExceededException).resetAt.toUtc();
      expect(resetAt.isAfter(DateTime.now().toUtc()), isTrue);
      expect(resetAt.hour, 0);
      expect(resetAt.minute, 0);
    });

    test(
      'other status:0 failure → plain ServerException, not the daily type',
      () async {
        when(
          () =>
              api.postRaw(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async => {
            'status': 0,
            'errorCode': 'SOMETHING_ELSE',
            'message': 'nope',
          },
        );

        final err = await fetchError();
        expect(err, isA<ServerException>());
        expect(err, isNot(isA<DailyViewsExceededException>()));
      },
    );
  });

  group('fetchFilters', () {
    test('hits the filters endpoint with no params', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {'status': 1, 'message': 'ok', 'data': const []},
      );

      await ds.fetchFilters();

      verify(() => api.get(EndPoints.discoveryFilters)).called(1);
    });
  });

  group('likeProfile — errorCode classification', () {
    // Gated failure arriving as a thrown CodedServerException (non-2xx or a
    // {success:false} envelope) is classified by the stable errorCode.
    void whenThrows(String code) => when(
      () => api.postRaw(any()),
    ).thenThrow(CodedServerException(message: 'server msg', errorCode: code));

    test('SUBSCRIPTION_REQUIRED → LikePaywall', () async {
      whenThrows(LikesErrorCodes.subscriptionRequired);
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('LIKES_QUOTA_EXCEEDED → LikePaywall', () async {
      whenThrows(LikesErrorCodes.likesQuotaExceeded);
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('LIKES_FREE_QUOTA_EXCEEDED → LikePaywall', () async {
      whenThrows(LikesErrorCodes.likesFreeQuotaExceeded);
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('LIKE_ALREADY_EXISTS → LikeAlreadyPending', () async {
      whenThrows(LikesErrorCodes.likeAlreadyExists);
      expect(await ds.likeProfile('u1'), isA<LikeAlreadyPending>());
    });

    test('SAME_GENDER_NOT_ALLOWED → LikeGenderMismatch', () async {
      whenThrows(LikesErrorCodes.sameGenderNotAllowed);
      expect(await ds.likeProfile('u1'), isA<LikeGenderMismatch>());
    });

    test('TARGET_USER_NOT_FOUND → LikeUserUnavailable', () async {
      whenThrows(LikesErrorCodes.targetUserNotFound);
      expect(await ds.likeProfile('u1'), isA<LikeUserUnavailable>());
    });

    test(
      '200 {status:0, errorCode} body is classified, NOT accepted',
      () async {
        when(() => api.postRaw(any())).thenAnswer(
          (_) async => {
            'status': 0,
            'errorCode': LikesErrorCodes.subscriptionRequired,
            'message': 'server msg',
          },
        );
        expect(await ds.likeProfile('u1'), isA<LikePaywall>());
      },
    );

    // No code → the generic key: `discovery_like_uncoded_test.dart` (H2).

    test('success {status:1, data} → LikeAccepted', () async {
      when(
        () => api.postRaw(any()),
      ).thenAnswer((_) async => {'status': 1, 'message': 'ok', 'data': '42'});
      final outcome = await ds.likeProfile('u1');
      expect(outcome, isA<LikeAccepted>());
      expect((outcome as LikeAccepted).likeId, '42');
    });

    test(
      'success {success:true, data} (no status) stays LikeAccepted',
      () async {
        // Regression guard: rejection is only flagged on a positive failure
        // marker, so a plain success Map without `status` is never mis-read.
        when(() => api.postRaw(any())).thenAnswer(
          (_) async => {'success': true, 'message': 'ok', 'data': '7'},
        );
        expect(await ds.likeProfile('u1'), isA<LikeAccepted>());
      },
    );
  });

  // The reset already happened server-side before any of this parsing runs, so
  // the count is advisory: no shape of `data` may turn a completed mutation
  // into a thrown error. Zero, however, is REAL information — it means nothing
  // was restored — and must survive as zero rather than being lost.
  group('resetSkippedProfiles', () {
    Map<String, dynamic> envelope(Object? data) => {
      'status': 1,
      'message': 'ok',
      'data': data,
    };

    test('posts to the reset route with no body', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope(115));

      await ds.resetSkippedProfiles();

      verify(() => api.post(EndPoints.discoverySkipReset)).called(1);
    });

    test('returns the restored count', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope(115));

      expect(await ds.resetSkippedProfiles(), 115);
    });

    test('zero survives as zero — the nothing-to-restore signal', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope(0));

      expect(await ds.resetSkippedProfiles(), 0);
    });

    test('a numeric string still reads as a count', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope('115'));

      expect(await ds.resetSkippedProfiles(), 115);
    });

    test('a missing count degrades to zero, not an error', () async {
      when(
        () => api.post(any()),
      ).thenAnswer((_) async => {'status': 1, 'message': 'ok'});

      expect(await ds.resetSkippedProfiles(), 0);
    });

    test('an unreadable count degrades to zero, not an error', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope('lots'));

      expect(await ds.resetSkippedProfiles(), 0);
    });

    test('a negative count is clamped rather than surfaced', () async {
      when(() => api.post(any())).thenAnswer((_) async => envelope(-3));

      expect(await ds.resetSkippedProfiles(), 0);
    });

    test('a non-map body degrades to zero', () async {
      when(() => api.post(any())).thenAnswer((_) async => 'unexpected');

      expect(await ds.resetSkippedProfiles(), 0);
    });

    // `post` enforces status == 1, so a failed envelope never reaches the
    // parser — it arrives as an exception the repository turns into a Left.
    test('a failed envelope propagates as a ServerException', () async {
      when(
        () => api.post(any()),
      ).thenThrow(ServerException(message: 'boom'));

      expect(() => ds.resetSkippedProfiles(), throwsA(isA<ServerException>()));
    });
  });
}
