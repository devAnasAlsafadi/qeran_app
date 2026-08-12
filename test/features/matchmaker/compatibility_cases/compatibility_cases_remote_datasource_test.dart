import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/data/datasources/compatibility_cases_remote_datasource.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/matchmaker_cases_filter.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

Map<String, dynamic> _emptyPage() => {
  'status': 1,
  'message': 'ok',
  'data': {
    'data': const <dynamic>[],
    'pageNumber': 1,
    'pageSize': 20,
    'totalCount': 0,
    'totalPages': 1,
  },
};

void main() {
  late _MockApiConsumer api;
  late CompatibilityCasesRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApiConsumer();
    dataSource = CompatibilityCasesRemoteDataSourceImpl(apiConsumer: api);
    when(
      () => api.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer((_) async => _emptyPage());
  });

  test('sends stage and activeFormalRequest as server-side filters', () async {
    await dataSource.getCases(
      page: 3,
      pageSize: 20,
      filter: const MatchmakerCasesFilter(
        stage: CompatibilityCaseStage.photoExchangeRejected,
        activeFormalRequest: true,
      ),
    );

    final captured = verify(
      () => api.get(
        captureAny(),
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured;

    expect(captured.first, EndPoints.matchmakerCompatibility);
    expect(captured.last, {
      'page': 3,
      'pageSize': 20,
      'stage': 3,
      'activeFormalRequest': true,
    });
  });

  test('omits optional query parameters when no filter is selected', () async {
    await dataSource.getCases(
      page: 1,
      pageSize: 20,
      filter: const MatchmakerCasesFilter(),
    );

    final query = verify(
      () => api.get(
        EndPoints.matchmakerCompatibility,
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single;

    expect(query, {'page': 1, 'pageSize': 20});
  });
}
