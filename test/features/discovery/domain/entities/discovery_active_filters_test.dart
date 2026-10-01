import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_active_filters.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/filter_payload_builders.dart';

void main() {
  test('none narrows nothing', () {
    expect(DiscoveryActiveFilters.none.isActive, isFalse);
    expect(DiscoveryActiveFilters.none.query, isNull);
    expect(DiscoveryActiveFilters.none.selections, isEmpty);
  });

  test('a null or empty query narrows nothing', () {
    for (final query in [null, <String, String>{}]) {
      final filters = DiscoveryActiveFilters(query: query);
      expect(filters.isActive, isFalse, reason: 'query $query');
      expect(filters.query, isNull, reason: 'query $query');
    }
  });

  test('a query narrows the deck, whatever the selections say', () {
    final filters = DiscoveryActiveFilters(
      query: const {'QuestionFilters[11]': 'SA'},
    );
    expect(filters.isActive, isTrue);
    expect(filters.query, {'QuestionFilters[11]': 'SA'});
  });

  test('selections alone narrow nothing', () {
    final filters = DiscoveryActiveFilters(
      selections: const {5: RangeSelection(min: 150, max: 200)},
    );
    expect(filters.isActive, isFalse);
    expect(filters.selections, hasLength(1));
  });

  test('holds copies the caller cannot change afterwards', () {
    final query = {'QuestionFilters[11]': 'SA'};
    final selections = <int, DiscoveryFilterSelection>{
      11: const SingleValueSelection('SA'),
    };
    final filters = DiscoveryActiveFilters(
      query: query,
      selections: selections,
    );
    query.clear();
    selections.clear();

    expect(filters.query, {'QuestionFilters[11]': 'SA'});
    expect(filters.selections, hasLength(1));
    expect(() => filters.query!['x'] = 'y', throwsUnsupportedError);
  });

  group('count — the number on the filter pill', () {
    // Built by the real serializer, so the count is checked against the keys
    // the sheet actually sends, not a hand-written guess at them.
    DiscoveryActiveFilters applied(Map<int, DiscoveryFilterSelection> picks) =>
        DiscoveryActiveFilters(
          query: buildDiscoveryFilterPayload(
            questions: _questions,
            selections: picks,
            logTag: 'TEST',
          ),
          selections: picks,
        );

    test('counts each question once, however many keys or values', () {
      final filters = applied(const {
        5: RangeSelection(min: 160, max: 180), // RangeFrom[5] + RangeTo[5]
        7: MultiValueSelection(['SA', 'KW', 'QA']), // one key, three values
        11: SingleValueSelection('single'),
      });
      expect(filters.query, hasLength(4));
      expect(filters.count, 3);
    });

    test('a range moved at one end counts once', () {
      final filters = applied(const {5: RangeSelection(min: 160, max: 210)});
      expect(filters.query, {'RangeFrom[5]': '160'});
      expect(filters.count, 1);
    });

    test('a range left at its full span counts nothing', () {
      final filters = applied(const {5: RangeSelection(min: 140, max: 210)});
      expect(filters.isActive, isFalse);
      expect(filters.count, 0);
    });

    test('is 0 exactly when nothing is active', () {
      expect(DiscoveryActiveFilters.none.count, 0);
      // A key without a question id still narrows the deck, so it counts.
      final odd = DiscoveryActiveFilters(query: const {'q': 'wider'});
      expect(odd.isActive, isTrue);
      expect(odd.count, 1);
    });
  });
}

const _questions = [
  DiscoveryFilterQuestion(
    id: 5,
    label: 'Height',
    type: FilterQuestionType.height,
    isRange: true,
    minValue: 140,
    maxValue: 210,
  ),
  DiscoveryFilterQuestion(
    id: 7,
    label: 'Nationality',
    type: FilterQuestionType.checkbox,
    isRange: false,
    isMultiSelect: true,
  ),
  DiscoveryFilterQuestion(
    id: 11,
    label: 'Marital status',
    type: FilterQuestionType.select,
    isRange: false,
  ),
];
