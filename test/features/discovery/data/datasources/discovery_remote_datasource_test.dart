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

  group('fetchPage — query parameter shape', () {
    test('spreads flat filterParams directly into the query map '
        '(no JSON encoding)', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _emptyPage());

      const filters = {
        'RangeFrom[1]': '18',
        'RangeTo[1]': '50',
        'RangeFrom[5]': '160',
        'RangeTo[5]': '180',
        'QuestionFilters[18]': 'Single',
        'QuestionFilters[11]': 'SA',
        'QuestionFilters[22]': 'Honest,Ambitious,FamilyOriented',
      };

      await ds.fetchPage(page: 1, pageSize: 20, filterParams: filters);

      final captured = verify(
        () => api.getRaw(
          captureAny(),
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured;

      expect(captured.first, EndPoints.discovery);
      final qp = captured.last as Map<String, dynamic>;
      // Page + size are always present.
      expect(qp['Page'], 1);
      expect(qp['PageSize'], 20);
      // Every flat filter key is spread in unchanged.
      filters.forEach((k, v) {
        expect(qp[k], v, reason: 'expected qp[$k]=$v');
      });
      // Critically: NO legacy "QuestionFilters" JSON-blob key.
      expect(qp.containsKey('QuestionFilters'), isFalse,
          reason: 'must not jsonEncode into a "QuestionFilters" blob');
    });

    test('null filterParams → only Page + PageSize sent', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _emptyPage());

      await ds.fetchPage();

      final qp = verify(
        () => api.getRaw(any(),
            queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(qp.keys.toSet(), {'Page', 'PageSize'});
    });

    test('empty filterParams behaves like null (no spread)', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _emptyPage());

      await ds.fetchPage(filterParams: const {});

      final qp = verify(
        () => api.getRaw(any(),
            queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(qp.keys.toSet(), {'Page', 'PageSize'});
    });
  });

  group('fetchPage — daily views cap', () {
    Future<Object?> fetchError() =>
        ds.fetchPage().then<Object?>((_) => null, onError: (e) => e);

    test('200 {status:0, DAILY_VIEWS_EXCEEDED, data.resetAt} → typed '
        'exception carrying the parsed resetAt', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'status': 0,
                'errorCode': DiscoveryErrorCodes.dailyViewsExceeded,
                'message': 'capped',
                'data': {'resetAt': '2026-07-18T00:00:00Z'},
              });

      final err = await fetchError();
      expect(err, isA<DailyViewsExceededException>());
      expect((err as DailyViewsExceededException).resetAt.toUtc(),
          DateTime.utc(2026, 7, 18));
    });

    test('non-2xx thrown CodedServerException with the code → typed '
        'exception (fallback resetAt = next UTC midnight)', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenThrow(CodedServerException(
        message: 'capped',
        errorCode: DiscoveryErrorCodes.dailyViewsExceeded,
      ));

      final err = await fetchError();
      expect(err, isA<DailyViewsExceededException>());
      final resetAt = (err as DailyViewsExceededException).resetAt.toUtc();
      expect(resetAt.isAfter(DateTime.now().toUtc()), isTrue);
      expect(resetAt.hour, 0);
      expect(resetAt.minute, 0);
    });

    test('other status:0 failure → plain ServerException, not the daily type',
        () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'status': 0,
                'errorCode': 'SOMETHING_ELSE',
                'message': 'nope',
              });

      final err = await fetchError();
      expect(err, isA<ServerException>());
      expect(err, isNot(isA<DailyViewsExceededException>()));
    });
  });

  group('fetchFilters', () {
    test('hits the filters endpoint with no params', () async {
      when(() => api.get(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'ok',
            'data': const [],
          });

      await ds.fetchFilters();

      verify(() => api.get(EndPoints.discoveryFilters)).called(1);
    });
  });

  group('likeProfile — errorCode classification', () {
    // Gated failure arriving as a thrown CodedServerException (non-2xx or a
    // {success:false} envelope) is classified by the stable errorCode.
    void whenThrows(String code) =>
        when(() => api.postRaw(any())).thenThrow(
          CodedServerException(message: 'server msg', errorCode: code),
        );

    test('SUBSCRIPTION_REQUIRED → LikePaywall', () async {
      whenThrows(LikesErrorCodes.subscriptionRequired);
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('LIKES_QUOTA_EXCEEDED → LikePaywall', () async {
      whenThrows(LikesErrorCodes.likesQuotaExceeded);
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

    test('200 {status:0, errorCode} body is classified, NOT accepted',
        () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'errorCode': LikesErrorCodes.subscriptionRequired,
            'message': 'server msg',
          });
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('Arabic message is the fallback when no errorCode', () async {
      when(() => api.postRaw(any())).thenThrow(
        ServerException(message: 'لقد استنفدت عدد الإعجابات المسموح به'),
      );
      expect(await ds.likeProfile('u1'), isA<LikePaywall>());
    });

    test('success {status:1, data} → LikeAccepted', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'ok',
            'data': '42',
          });
      final outcome = await ds.likeProfile('u1');
      expect(outcome, isA<LikeAccepted>());
      expect((outcome as LikeAccepted).likeId, '42');
    });

    test('success {success:true, data} (no status) stays LikeAccepted',
        () async {
      // Regression guard: rejection is only flagged on a positive failure
      // marker, so a plain success Map without `status` is never mis-read.
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'success': true,
            'message': 'ok',
            'data': '7',
          });
      expect(await ds.likeProfile('u1'), isA<LikeAccepted>());
    });
  });
}
