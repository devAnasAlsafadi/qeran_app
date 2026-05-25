import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/discovery/data/datasources/discovery_remote_datasource.dart';

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
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
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
        () => api.get(
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
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _emptyPage());

      await ds.fetchPage();

      final qp = verify(
        () => api.get(any(),
            queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(qp.keys.toSet(), {'Page', 'PageSize'});
    });

    test('empty filterParams behaves like null (no spread)', () async {
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => _emptyPage());

      await ds.fetchPage(filterParams: const {});

      final qp = verify(
        () => api.get(any(),
            queryParameters: captureAny(named: 'queryParameters')),
      ).captured.single as Map<String, dynamic>;

      expect(qp.keys.toSet(), {'Page', 'PageSize'});
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
}
