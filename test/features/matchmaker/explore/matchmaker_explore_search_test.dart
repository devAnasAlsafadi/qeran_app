import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart';

class _MockApi extends Mock implements ApiConsumer {}

/// Run 11 (Tariq's deploy, captured 2026-10-15: 200, the GET's envelope):
/// her explore list is `POST matchmaker/explore/search`, everything in the
/// body, so no filter set outgrows the query string.
void main() {
  late _MockApi api;
  late MatchmakerExploreRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApi();
    ds = MatchmakerExploreRemoteDataSourceImpl(apiConsumer: api);
    when(() => api.post(any(), body: any(named: 'body'))).thenAnswer(
      (_) async => {
        'status': 1,
        'message': 'ok',
        'data': {
          'data': const [],
          'pageNumber': 1,
          'pageSize': 3,
          'totalCount': 0,
          'totalPages': 0,
        },
      },
    );
  });

  Map<String, dynamic> sentBody() {
    final captured = verify(
      () => api.post(captureAny(), body: captureAny(named: 'body')),
    ).captured;
    expect(captured.first, 'matchmaker/explore/search');
    return captured.last as Map<String, dynamic>;
  }

  test('search, gender, choices and ranges all go in the body', () async {
    await ds.getExplore(
      page: 2,
      pageSize: 20,
      search: '  Dima ',
      gender: Gender.female,
      questionFilters: const {
        18: ['Single'],
        22: ['Honest', '', 'Ambitious'],
      },
      rangeFrom: const {1: 18, 5: 160.5},
      rangeTo: const {1: 50},
    );

    expect(sentBody(), {
      'page': 2,
      'pageSize': 20,
      'search': 'Dima',
      'gender': Gender.female.apiValue,
      'questionFilters': {'18': 'Single', '22': 'Honest,Ambitious'},
      'rangeFrom': {'1': 18, '5': 160.5},
      'rangeTo': {'1': 50},
    });
    verifyNever(
      () => api.get(any(), queryParameters: any(named: 'queryParameters')),
    );
  });

  test('nothing chosen: page and pageSize only', () async {
    await ds.getExplore(
      page: 1,
      pageSize: 3,
      search: '   ',
      questionFilters: const {
        7: [''],
      },
    );

    expect(sentBody(), {'page': 1, 'pageSize': 3});
  });

  test('whole range edges are integers, not 18.0', () async {
    await ds.getExplore(page: 1, pageSize: 3, rangeFrom: const {1: 18});

    expect((sentBody()['rangeFrom'] as Map)['1'], isA<int>());
  });
}
