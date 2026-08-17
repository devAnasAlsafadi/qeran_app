import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/matchmaker/explore/data/datasources/matchmaker_explore_remote_datasource.dart';

/// The matchmaker's `/filters` datasource is where the two apps genuinely
/// diverge, so it needs its own coverage even though the MODEL is shared with
/// discovery (already covered by `discovery_filter_question_model_test.dart`):
///
///   • discovery returns `data` as a flat List
///   • explore returns `data` as an OBJECT `{ gender, questions }`
///   • explore names the question text `label`; the shared model reads `question`
///   • the `gender` facet is deliberately dropped — gender is a hardcoded
///     screen-level segment, not a sheet facet
class _MockApiConsumer extends Mock implements ApiConsumer {}

Map<String, dynamic> _envelope(Object? data) => {
  'status': 1,
  'message': null,
  'data': data,
};

Map<String, dynamic> _question({
  int id = 11,
  String? label = 'Nationality',
  String? question,
  String type = 'select',
  bool isRange = false,
  List<Map<String, dynamic>>? options,
  int? minValue,
  int? maxValue,
  String? unit,
}) => {
  'questionId': id,
  'label': ?label,
  'question': ?question,
  'type': type,
  'isRange': isRange,
  'options': ?options,
  'minValue': ?minValue,
  'maxValue': ?maxValue,
  'unit': ?unit,
};

void main() {
  late _MockApiConsumer api;
  late MatchmakerExploreRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _MockApiConsumer();
    dataSource = MatchmakerExploreRemoteDataSourceImpl(apiConsumer: api);
  });

  void stub(Object? data) {
    when(
      () => api.get(any(), queryParameters: any(named: 'queryParameters')),
    ).thenAnswer((_) async => _envelope(data));
  }

  group('getFilters — the object envelope', () {
    test('hits the explore filters endpoint', () async {
      stub({'questions': const []});

      await dataSource.getFilters();

      verify(() => api.get(EndPoints.matchmakerExploreFilters)).called(1);
    });

    test('unwraps `questions` out of the object (not a flat list)', () async {
      stub({
        'gender': 'Male',
        'questions': [_question(id: 11), _question(id: 18, type: 'radio')],
      });

      final result = await dataSource.getFilters();

      expect(result, hasLength(2));
      expect(result.first.questionId, 11);
      expect(result.last.questionId, 18);
    });

    test('the gender facet is dropped, not rendered as a question', () async {
      // Gender is a hardcoded segmented control above the sheet. If it ever
      // leaked through as a facet the matchmaker would get two competing
      // gender controls.
      stub({
        'gender': {
          'questionId': 999,
          'label': 'Gender',
          'type': 'radio',
          'options': [
            {'value': 'Male', 'display': 'Male'},
          ],
        },
        'questions': [_question(id: 11)],
      });

      final result = await dataSource.getFilters();

      expect(result, hasLength(1));
      expect(result.single.questionId, 11);
      expect(result.any((q) => q.questionId == 999), isFalse);
    });

    test('missing `questions` reads as no facets, not a crash', () async {
      stub({'gender': 'Male'});

      expect(await dataSource.getFilters(), isEmpty);
    });

    test('a flat list (discovery\'s shape) yields no facets here', () async {
      // Defensive: if the backend ever unified the two shapes, this surfaces as
      // "no filters available" rather than a cast crash.
      stub([_question(id: 11)]);

      expect(await dataSource.getFilters(), isEmpty);
    });

    test('non-map entries inside questions are skipped', () async {
      stub({
        'questions': ['nonsense', 42, _question(id: 11), null],
      });

      final result = await dataSource.getFilters();

      expect(result, hasLength(1));
      expect(result.single.questionId, 11);
    });

    test('data: null throws with the server message', () async {
      when(
        () => api.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => {'status': 1, 'message': 'errors.generic', 'data': null},
      );

      expect(
        () => dataSource.getFilters(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getFilters — the label alias', () {
    test('explore\'s `label` populates the shared model\'s `question`',
        () async {
      // The shared model reads `question` (discovery's field name); explore
      // sends `label`. Without the alias every facet would render blank.
      stub({
        'questions': [_question(id: 11, label: 'الجنسية')],
      });

      final result = await dataSource.getFilters();

      expect(result.single.question, 'الجنسية');
    });

    test('an explicit `question` wins over `label`', () async {
      stub({
        'questions': [
          _question(id: 11, label: 'from-label', question: 'from-question'),
        ],
      });

      final result = await dataSource.getFilters();

      expect(result.single.question, 'from-question');
    });

    test('a full question round-trips to the entity intact', () async {
      stub({
        'questions': [
          _question(
            id: 5,
            label: 'Height',
            type: 'height',
            isRange: true,
            minValue: 140,
            maxValue: 210,
            unit: 'سم',
          ),
        ],
      });

      final entity = (await dataSource.getFilters()).single.toEntity();

      expect(entity.id, 5);
      expect(entity.label, 'Height');
      expect(entity.type, FilterQuestionType.height);
      expect(entity.isRange, isTrue);
      expect(entity.minValue, 140);
      expect(entity.maxValue, 210);
      expect(entity.unit, 'سم');
      expect(entity.options, isNull);
    });
  });
}
