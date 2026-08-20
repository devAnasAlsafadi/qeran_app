import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/badges/data/datasources/badges_remote_datasource.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';

class _MockApi extends Mock implements ApiConsumer {}

void main() {
  late _MockApi api;
  late BadgesRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApi();
    dataSource = BadgesRemoteDataSourceImpl(apiConsumer: api);
  });

  group('getBadges', () {
    test('reads the counts off the badges endpoint', () async {
      when(() => api.getRaw(EndPoints.badges)).thenAnswer(
        (_) async => {BadgeTabKeys.likes: 2, BadgeTabKeys.notifications: 5},
      );

      final counts = await dataSource.getBadges();

      expect(counts.likes, 2);
      expect(counts.notifications, 5);
    });

    // Pre-deploy grace: an older client can meet a server without the route.
    // That is not a fault the user should ever see — it reads as "no badges",
    // exactly like an empty dict.
    test('a 404 reads as no badges rather than an error', () async {
      when(() => api.getRaw(EndPoints.badges)).thenThrow(
        CodedServerException(
          message: 'errors.not_found',
          errorCode: null,
          statusCode: 404,
        ),
      );

      final counts = await dataSource.getBadges();

      expect(counts.likes, 0);
      expect(counts.notifications, 0);
    });

    // The 404 branch must stay narrow. Swallowing a 500 or an expired token
    // would hide a real fault behind a navigation bar that looks fine.
    test('any other coded failure still throws', () async {
      when(() => api.getRaw(EndPoints.badges)).thenThrow(
        CodedServerException(
          message: 'errors.server',
          errorCode: null,
          statusCode: 500,
        ),
      );

      expect(dataSource.getBadges(), throwsA(isA<CodedServerException>()));
    });

    test('an offline failure still throws', () async {
      when(
        () => api.getRaw(EndPoints.badges),
      ).thenThrow(const OfflineException());

      expect(dataSource.getBadges(), throwsA(isA<OfflineException>()));
    });
  });

  group('markTabSeen', () {
    test('posts the tab key in the body the server expects', () async {
      when(
        () => api.postRaw(EndPoints.badgesMarkSeen, body: any(named: 'body')),
      ).thenAnswer((_) async => null);

      await dataSource.markTabSeen(BadgeTabKeys.likes);

      final captured = verify(
        () => api.postRaw(
          EndPoints.badgesMarkSeen,
          body: captureAny(named: 'body'),
        ),
      ).captured.single;
      expect(captured, {'tab': BadgeTabKeys.likes});
    });

    test('propagates failures so the repository can log them', () async {
      when(
        () => api.postRaw(EndPoints.badgesMarkSeen, body: any(named: 'body')),
      ).thenThrow(ServerException(message: 'errors.generic'));

      expect(
        dataSource.markTabSeen(BadgeTabKeys.likes),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
