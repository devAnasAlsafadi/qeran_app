import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/features/likes/data/datasources/photo_view_remote_datasource.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late _MockApiConsumer api;
  late PhotoViewRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApiConsumer();
    dataSource = PhotoViewRemoteDataSourceImpl(apiConsumer: api);
  });

  test('GET permission parses the documented state', () async {
    when(() => api.get('photo-exchange/permission/u1')).thenAnswer(
      (_) async => {
        'status': 1,
        'data': {
          'targetUserId': 'u1',
          'photoExchangeId': 42,
          'isUnblurred': false,
          'viewedAt': null,
          'viewExpiresAt': null,
          'isConsumed': false,
        },
      },
    );

    final permission = await dataSource.getPermission('u1');

    expect(permission.targetUserId, 'u1');
    expect(permission.photoExchangeId, 42);
    expect(permission.isUnblurred, isFalse);
    expect(permission.isConsumed, isFalse);
    verify(() => api.get('photo-exchange/permission/u1')).called(1);
  });

  test('POST view parses server secondsRemaining', () async {
    when(() => api.post('photo-exchange/42/view')).thenAnswer(
      (_) async => {
        'status': 1,
        'data': {
          'photoExchangeId': 42,
          'viewedAt': '2026-08-11T18:20:00Z',
          'viewExpiresAt': '2026-08-11T18:21:00Z',
          'secondsRemaining': 60,
        },
      },
    );

    final session = await dataSource.beginView(42);

    expect(session.photoExchangeId, 42);
    expect(session.secondsRemaining, 60);
    verify(() => api.post('photo-exchange/42/view')).called(1);
  });
}
